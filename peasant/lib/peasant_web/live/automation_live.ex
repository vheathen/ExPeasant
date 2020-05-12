defmodule PeasantWeb.AutomationLive do
  use PeasantWeb, :live_view

  require Logger

  import PeasantWeb.LiveHelpers

  import PeasantWeb.AutomationsHelpers
  import PeasantWeb.ToolsHelpers

  alias Peasant.Automation.Event, as: Automation
  alias Peasant.Automation.State

  @tick_duration 50

  @automations Peasant.Automation.domain()

  @active_color %{
    true => "green",
    false => "dark-gray"
  }

  @current_step_bg %{
    true => "bg-lightgreen",
    false => ""
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Phoenix.LiveView.assign(socket, :menu, %{
        action: socket.assigns.live_action
      })

    Peasant.subscribe(@automations)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {
      :noreply,
      assign(
        socket,
        params: params,
        steps_log: %{},
        current_step_uuid: nil,
        timer_ref: nil,
        form_disabled: false,
        step: nil,
        step_position: 1
      )
      |> apply_action(params)
      |> maybe_activate()
    }
  end

  defp apply_action(socket, %{"id" => uuid} = _params),
    do: fetch_automation(socket, uuid)

  defp apply_action(socket, _params),
    do:
      assign(
        socket,
        automation: %State{},
        changeset: %State{} |> Peasant.Automations.change_automation(),
        uuid: nil
      )
      |> set_page_title()

  defp fetch_automation(socket, uuid) do
    assign(
      socket,
      automation: get_automation(uuid),
      uuid: uuid
    )
    |> set_page_title()
  end

  defp maybe_activate(
         %{
           assigns: %{
             automation: %{
               uuid: uuid,
               last_step_index: index,
               last_step_attempted_at: timestamp,
               total_steps: total_steps,
               steps: steps,
               active: true
             }
           }
         } = socket
       )
       when not is_nil(uuid) and total_steps > 0 do
    %{uuid: step_uuid} = Enum.at(steps, index)

    start_step(socket, step_uuid, timestamp)
  end

  defp maybe_activate(socket) do
    socket
    |> stop_timer()
    |> assign(
      current_step_uuid: nil,
      current_step_duration: 0
    )
  end

  @impl true
  def handle_event("validate", %{"state" => automation_params}, socket) do
    changeset =
      socket.assigns.automation
      |> Peasant.Automations.change_automation(automation_params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("create", %{"state" => automation_params}, socket) do
    {:noreply, create_automation(socket, automation_params)}
  end

  def handle_event("revert_state", _value, socket) do
    {type, message} =
      case socket.assigns.automation.active do
        true ->
          Peasant.Automation.deactivate(socket.assigns.uuid)
          {:success, "Automation deactivated"}

        _ ->
          case Peasant.Automation.activate(socket.assigns.uuid) do
            :ok -> {:success, "Automation activated"}
            {:error, error} -> {:error, error}
          end
      end

    {:noreply, put_flash(socket, type, message)}
  end

  def handle_event("add_step_at", %{"position" => position}, socket) do
    step = %Peasant.Automation.State.Step{}
    position = String.to_integer(position)

    {:noreply, assign(socket, step: step, step_position: position)}
  end

  def handle_event("delete_step", %{"uuid" => step_uuid}, socket) do
    Peasant.Automation.delete_step(socket.assigns.uuid, step_uuid)

    {:noreply, put_flash(socket, :success, "Step deleted")}
  end

  def handle_event("revert_step_state", %{"uuid" => step_uuid, "index" => step_index}, socket) do
    step = Enum.at(socket.assigns.automation.steps, String.to_integer(step_index))

    case step.active do
      true ->
        Peasant.Automation.deactivate_step(socket.assigns.uuid, step_uuid)

      _ ->
        Peasant.Automation.activate_step(socket.assigns.uuid, step_uuid)
    end

    {:noreply, socket}
  end

  def handle_event("edit_step", %{"uuid" => _step_uuid, "index" => step_index}, socket) do
    index = String.to_integer(step_index)

    step =
      socket.assigns.automation.steps
      |> Enum.at(index)

    position = index + 1

    {:noreply, assign(socket, step: step, step_position: position)}
  end

  defp create_automation(socket, automation_params) do
    case Peasant.Automation.create(automation_params) do
      {:ok, uuid} ->
        assign(socket, uuid: uuid, form_disabled: true)

      {:error, errors} ->
        assign(socket,
          changeset: %{
            socket.assigns.changeset
            | valid?: false,
              errors: errors,
              action: :insert
          }
        )
    end
  end

  @impl true
  def handle_info(
        %Automation.Created{automation_uuid: uuid},
        %{assigns: %{uuid: uuid}} = socket
      ) do
    {:noreply, push_patch(socket, to: self_path(socket, [uuid], %{}))}
  end

  def handle_info(
        %Automation.Activated{automation_uuid: uuid},
        %{assigns: %{uuid: uuid}} = socket
      ) do
    socket =
      socket
      |> assign(automation: %{socket.assigns.automation | active: true})
      |> maybe_activate()

    {:noreply, socket}
  end

  def handle_info(
        %Automation.Deactivated{automation_uuid: uuid},
        %{assigns: %{uuid: uuid}} = socket
      ) do
    socket =
      socket
      |> assign(automation: %{socket.assigns.automation | active: false})
      |> maybe_activate()

    {:noreply, socket}
  end

  def handle_info(
        %Automation.Renamed{automation_uuid: uuid, name: name},
        %{assigns: %{uuid: uuid}} = socket
      ) do
    {
      :noreply,
      assign(socket, automation: %{socket.assigns.automation | name: name})
    }
  end

  def handle_info(
        %Automation.StepSkipped{automation_uuid: uuid, step_uuid: step_uuid},
        %{assigns: %{uuid: uuid, steps_log: steps_log}} = socket
      ) do
    {
      :noreply,
      assign(socket,
        steps_log: Map.put(steps_log, step_uuid, "skipped")
      )
    }
  end

  def handle_info(
        %Automation.StepStarted{
          automation_uuid: uuid,
          step_uuid: step_uuid,
          timestamp: current_step_started_at
        },
        %{assigns: %{uuid: uuid}} = socket
      ) do
    {
      :noreply,
      start_step(socket, step_uuid, current_step_started_at)
    }
  end

  def handle_info(
        %Automation.StepStopped{
          automation_uuid: uuid,
          step_uuid: step_uuid,
          step_duration: duration
        },
        %{assigns: %{uuid: uuid, steps_log: steps_log}} = socket
      ) do
    {
      :noreply,
      socket
      |> stop_timer()
      |> assign(
        steps_log: Map.put(steps_log, step_uuid, duration),
        current_step_uuid: nil,
        current_step_duration: 0
      )
    }
  end

  def handle_info(
        %Automation.StepFailed{
          automation_uuid: uuid,
          step_uuid: step_uuid,
          step_duration: _duration,
          details: error
        },
        %{assigns: %{uuid: uuid, steps_log: steps_log}} = socket
      ) do
    {
      :noreply,
      socket
      |> stop_timer()
      |> assign(
        steps_log: Map.put(steps_log, step_uuid, "#{inspect(error)}"),
        current_step_uuid: nil,
        current_step_duration: 0
      )
    }
  end

  # On any other event just soft-reload liveview
  def handle_info(
        %type{automation_uuid: uuid} = event,
        %{assigns: %{uuid: uuid}} = socket
      ) do
    Logger.debug("Catch all handler, type: #{type}, event: #{inspect(event)}")
    {:noreply, push_patch(socket, to: self_path(socket, [uuid], %{}))}
  end

  def handle_info(:refresh, socket) do
    {:noreply, apply_action(socket, socket.assigns.params)}
  end

  def handle_info({:timer_tick, started_at}, socket) do
    {:noreply,
     socket
     |> start_timer()
     |> assign(current_step_duration: socket.assigns.current_step_duration + (now() - started_at))}
  end

  def handle_info(msg, socket) do
    Logger.debug("Unhandled message: #{inspect(msg)}")
    socket
  end

  defp self_path(socket, args \\ [], params) do
    live_peasant_path(socket, :automation, args, params)
  end

  defp active_color(state), do: @active_color[state]

  defp get_tool_details(step) do
    case get_tool(step.tool_uuid) do
      %type{name: name} -> {type, name}
      _ -> {nil, nil}
    end
  end

  defp current_step_bg(current_step?),
    do: @current_step_bg[current_step?]

  # defp step_type("awaiting") do
  #   ~s(
  #   <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
  #   viewBox="0 0 512 512" enable-background="new 0 0 512 512" xml:space="preserve">
  #     <path d="M256,96C141.125,96,48,189.125,48,304s93.125,208,208,208s208-93.125,208-208S370.875,96,256,96z M272,479.188V464
  #       c0-8.844-7.156-16-16-16s-16,7.156-16,16v15.188C155.719,471.531,88.438,404.281,80.813,320H96c8.844,0,16-7.156,16-16
  #       s-7.156-16-16-16H80.813C88.438,203.719,155.719,136.438,240,128.813V144c0,8.844,7.156,16,16,16s16-7.156,16-16v-15.188
  #       c84.281,7.625,151.531,74.906,159.188,159.188H416c-8.844,0-16,7.156-16,16s7.156,16,16,16h15.188
  #       C423.531,404.281,356.281,471.531,272,479.188z M208,48V16c0-8.844,7.156-16,16-16h64c8.844,0,16,7.156,16,16v32
  #       c0,8.844-7.156,16-16,16v18.563C277.5,81.063,266.875,80,256,80s-21.5,1.063-32,2.563V64C215.156,64,208,56.844,208,48z
  #       M394.031,127.938C377.531,115,359.25,104.281,339.5,96.313c0.313-0.75,0.375-1.563,0.781-2.313l16-27.688
  #       c4.438-7.688,14.219-10.313,21.875-5.875l27.688,16c7.656,4.438,10.281,14.188,5.875,21.875l-16,27.688
  #       C395.281,126.781,394.563,127.25,394.031,127.938z M394.563,224c4.438,7.656,1.813,17.438-5.844,21.875L264,317.844
  #       c-2.469,1.438-5.25,2.156-8,2.156s-5.531-0.719-8-2.156l-124.688-71.969c-7.688-4.438-10.313-14.219-5.875-21.875
  #       s14.219-10.281,21.875-5.875L256,285.531l116.719-67.406C380.406,213.75,390.188,216.375,394.563,224z"/>
  #   </svg>
  #   )
  #   |> raw()
  # end

  # defp step_type("action") do
  #   ~s(
  #   <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
  #   viewBox="0 0 512 512" enable-background="new 0 0 512 512" xml:space="preserve">
  #     <path d="M348,327.195v-35.741l-32.436-11.912c-2.825-10.911-6.615-21.215-12.216-30.687l0.325-0.042l15.438-32.153l-25.2-25.269
  #       l-32.118,15.299l-0.031,0.045c-9.472-5.601-19.758-9.156-30.671-11.978L219.186,162h-35.739l-11.913,32.759
  #       c-10.913,2.821-21.213,6.774-30.685,12.379l-0.048-0.248l-32.149-15.399l-25.269,25.219l15.299,32.124l0.05,0.039
  #       c-5.605,9.471-11.159,19.764-13.98,30.675L50,291.454v35.741l34.753,11.913c2.821,10.915,7.774,21.211,13.38,30.685l0.249,0.045
  #       l-15.147,32.147l25.343,25.274l32.188-15.298l0.065-0.046c9.474,5.597,19.782,10.826,30.695,13.652L183.447,460h35.739
  #       l11.915-34.432c10.913-2.826,21.209-7.614,30.681-13.215l0.05-0.175l32.151,15.192l25.267-25.326l-15.299-32.182l-0.046-0.061
  #       c5.601-9.473,8.835-19.776,11.66-30.688L348,327.195z M201.318,368.891c-32.897,0-59.566-26.662-59.566-59.565
  #       c0-32.896,26.669-59.568,59.566-59.568c32.901,0,59.566,26.672,59.566,59.568C260.884,342.229,234.219,368.891,201.318,368.891z"/>
  #     <path d="M462.238,111.24l-7.815-18.866l-20.23,1.012c-3.873-5.146-8.385-9.644-13.417-13.42l0.038-0.043l1.06-20.318l-18.859-7.822
  #       L389.385,66.89l-0.008,0.031c-6.229-0.883-12.619-0.933-18.988-0.025L356.76,51.774l-18.867,7.815l1.055,20.32
  #       c-5.152,3.873-9.627,8.422-13.403,13.46l-0.038-0.021l-20.317-1.045l-7.799,18.853l15.103,13.616l0.038,0.021
  #       c-0.731,5.835-1.035,12.658-0.133,19.038l-15.208,13.662l7.812,18.87l20.414-1.086c3.868,5.144,8.472,9.613,13.495,13.385
  #       l0.013,0.025l-1.03,20.312l20.668,7.815L374,201.703v-0.033c4,0.731,10.818,0.935,17.193,0.04l12.729,15.114l18.42-7.813
  #       l-1.286-20.324c5.144-3.875,9.521-8.424,13.297-13.456l-0.023,0.011l20.287,1.047l7.802-18.864l-15.121-13.624l-0.033-0.019
  #       c0.877-6.222,0.852-12.58-0.05-18.953L462.238,111.24z M392.912,165.741c-17.359,7.19-37.27-1.053-44.462-18.421
  #       c-7.196-17.364,1.047-37.272,18.415-44.465c17.371-7.192,37.274,1.053,44.471,18.417
  #       C418.523,138.643,410.276,158.547,392.912,165.741z"/>
  #   </svg>
  #   )
  #   |> raw()
  # end

  defp start_timer(socket),
    do:
      socket
      |> stop_timer()
      |> assign(timer_ref: Process.send_after(self(), {:timer_tick, now()}, @tick_duration))

  defp stop_timer(socket) do
    socket.assigns[:timer_ref] &&
      is_reference(socket.assigns.timer_ref) &&
      Process.cancel_timer(socket.assigns.timer_ref)

    socket
  end

  defp start_step(socket, step_uuid, current_step_started_at),
    do:
      socket
      |> start_timer()
      |> assign(
        current_step_uuid: step_uuid,
        current_step_duration: now() - current_step_started_at
      )

  defp set_page_title(socket) do
    title =
      cond do
        socket.assigns.uuid && is_nil(socket.assigns.automation) -> "Not found"
        socket.assigns.automation.new -> "New automation"
        true -> socket.assigns.automation.name
      end

    assign(socket, page_title: title)
  end

  defp step_info(
         uuid,
         %{uuid: uuid, type: "action"} = _step,
         current_step_duration,
         _
       ) do
    """
    <small>Duration:</small><br />
    #{format_number(current_step_duration)} ms
    """
  end

  defp step_info(
         uuid,
         %{uuid: uuid, type: "awaiting"} = step,
         current_step_duration,
         _
       ) do
    """
    <small>Time left:</small><br />
    #{format_number(step.time_to_wait - current_step_duration)} ms
    """
  end

  defp step_info(_uuid, %{uuid: uuid} = _step, _current_step_duration, steps_log) do
    cond do
      steps_log[uuid] && is_number(steps_log[uuid]) ->
        """
        <small>Last duration:</small><br />
        #{format_number(steps_log[uuid])} ms
        """

      steps_log[uuid] ->
        """
        <small>Last run details:</small><br />
        #{steps_log[uuid]}
        """

      true ->
        ""
    end
  end

  defp now,
    do: DateTime.utc_now() |> DateTime.to_unix(:millisecond)
end
