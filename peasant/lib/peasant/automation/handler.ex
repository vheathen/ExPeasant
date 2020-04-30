defmodule Peasant.Automation.Handler do
  use GenServer

  @automations Peasant.Automation.domain()

  @awaiting "awaiting"
  @action "action"

  alias Peasant.Automation.State
  alias Peasant.Automation.State.Step
  alias Peasant.Automation.Event

  import Peasant.Helper

  ###
  # Internal Public API
  #

  def start_link(%{uuid: uuid} = automation),
    do: GenServer.start_link(__MODULE__, automation, name: via_tuple(uuid))

  def create(automation),
    do: __MODULE__ |> handler_child_spec(automation) |> Peasant.ActivityMaster.add()

  def rename(automation_uuid, new_name), do: try_action(automation_uuid, {:rename, new_name})

  def activate(automation_uuid), do: try_action(automation_uuid, :activate)

  def deactivate(automation_uuid), do: try_action(automation_uuid, :deactivate)

  def add_step_at(automation_uuid, step, position),
    do: try_action(automation_uuid, {:add_step_at, step, position})

  def delete_step(automation_uuid, step_uuid),
    do: try_action(automation_uuid, {:delete_step, step_uuid})

  def rename_step(automation_uuid, step_uuid, new_name),
    do: try_action(automation_uuid, {:rename_step, step_uuid, new_name})

  def move_step_to(automation_uuid, step_uuid, position),
    do: try_action(automation_uuid, {:move_step_to, step_uuid, position})

  def activate_step(automation_uuid, step_uuid),
    do: try_action(automation_uuid, {:activate_step, step_uuid})

  def deactivate_step(automation_uuid, step_uuid),
    do: try_action(automation_uuid, {:deactivate_step, step_uuid})

  defp try_action(uuid, action) do
    try do
      GenServer.call(via_tuple(uuid), action)
    catch
      :exit, {:noproc, _} -> {:error, :no_automation_exists}
    end
  end

  ####
  # Implementation
  #

  def init(%State{new: true} = automation),
    do: {:ok, %{automation | new: false}, {:continue, :created}}

  def init(%State{} = automation),
    do: {:ok, automation, {:continue, :loaded}}

  def handle_continue(:created, automation) do
    [automation_uuid: automation.uuid, automation: automation]
    |> Peasant.Automation.Event.Created.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        :loaded,
        automation
      ) do
    [automation_uuid: automation.uuid, automation: automation]
    |> Peasant.Automation.Event.Loaded.new()
    |> notify()

    {:noreply, automation, {:continue, :maybe_activate}}
  end

  def handle_continue(
        :maybe_activate,
        %{active: false} = automation
      ),
      do: {:noreply, automation}

  def handle_continue(
        :maybe_activate,
        %{active: true} = automation
      ),
      do: {:noreply, automation, {:continue, :activated}}

  def handle_continue(
        :activated,
        automation
      ) do
    [automation_uuid: automation.uuid]
    |> Event.Activated.new()
    |> notify()

    {:noreply, %{automation | last_step_index: -1}, {:continue, :next_step}}
  end

  def handle_continue(
        :deactivated,
        %{steps: steps, last_step_index: last_step_index, timer: timer} = automation
      ) do
    %{uuid: current_step_uuid} = Enum.at(steps, last_step_index)

    stop_timer(timer)
    automation = %{automation | timer: nil, timer_ref: nil}

    finish_step(current_step_uuid, automation)

    [automation_uuid: automation.uuid]
    |> Event.Deactivated.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        :next_step,
        %{active: false} = automation
      ),
      do: {:noreply, automation}

  def handle_continue(
        :next_step,
        %{total_steps: total_steps, last_step_index: last_step_index} = automation
      )
      when last_step_index + 1 == total_steps,
      do: {:noreply, %{automation | last_step_index: -1}, {:continue, :next_step}}

  def handle_continue(
        :next_step,
        %{steps: steps, last_step_index: last_step_index} = automation
      ) do
    current_step_index = last_step_index + 1
    current_step = Enum.at(steps, current_step_index)

    automation = %{
      automation
      | last_step_index: current_step_index
    }

    {:noreply, automation, {:continue, {:start_step, current_step}}}
  end

  def handle_continue({_, %Step{active: false}}, automation),
    do: {:noreply, automation, {:continue, :next_step}}

  def handle_continue({:start_step, _current_step}, %{active: false} = automation),
    do: {:noreply, automation}

  def handle_continue(
        {:start_step, current_step},
        %{last_step_index: current_step_index} = automation
      ) do
    step_started_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    automation = %{
      automation
      | last_step_started_timestamp: step_started_timestamp
    }

    [
      automation_uuid: automation.uuid,
      step_uuid: current_step.uuid,
      step_position: current_step_index + 1,
      timestamp: step_started_timestamp
    ]
    |> Event.StepStarted.new()
    |> notify()

    {:noreply, automation, {:continue, {:do_step, current_step}}}
  end

  def handle_continue(
        {:do_step, %Step{uuid: step_uuid, type: @awaiting, time_to_wait: time_to_wait}},
        automation
      )
      when is_integer(time_to_wait) do
    timer = Process.send_after(self(), {:waiting_finished, step_uuid}, time_to_wait)

    {:noreply, %{automation | timer: timer, timer_ref: step_uuid}}
  end

  def handle_continue(
        {:do_step,
         %Step{
           type: @action,
           tool_uuid: tool_uuid,
           action: action,
           action_config: action_config
         } = current_step},
        automation
      ) do
    case Peasant.Tool.commit(tool_uuid, action, action_config) do
      {:error, error} ->
        {:noreply, automation, {:continue, {:fail_step, current_step.uuid, error}}}

      _ ->
        {:noreply, automation, {:continue, {:finish_step, current_step.uuid}}}
    end
  end

  def handle_continue(
        {:finish_step, current_step_uuid},
        automation
      ) do
    finish_step(current_step_uuid, automation)

    {:noreply, automation, {:continue, :next_step}}
  end

  def handle_continue(
        {:fail_step, current_step_uuid, error},
        %{
          last_step_index: current_step_index,
          last_step_started_timestamp: step_started_timestamp
        } = automation
      ) do
    step_stopped_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    [
      automation_uuid: automation.uuid,
      step_uuid: current_step_uuid,
      step_position: current_step_index + 1,
      timestamp: step_stopped_timestamp,
      step_duration: step_stopped_timestamp - step_started_timestamp,
      details: error
    ]
    |> Event.StepFailed.new()
    |> notify()

    {:noreply, automation, {:continue, :next_step}}
  end

  def handle_call({:rename, new_name}, _from, %{name: new_name} = automation),
    do: {:reply, :ok, automation}

  def handle_call({:rename, new_name}, _from, automation) do
    [automation_uuid: automation.uuid, name: new_name]
    |> Event.Renamed.new()
    |> notify()

    {:reply, :ok, %{automation | name: new_name}}
  end

  def handle_call(:activate, _from, %{active: true} = automation),
    do: {:reply, :ok, automation}

  def handle_call(:activate, _from, automation),
    do: {:reply, :ok, %{automation | active: true}, {:continue, :activated}}

  def handle_call(:deactivate, _from, %{active: false} = automation),
    do: {:reply, :ok, automation}

  def handle_call(:deactivate, _from, automation),
    do: {:reply, :ok, %{automation | active: false}, {:continue, :deactivated}}

  #
  # step operations
  #

  def handle_call(_, _from, %{active: true} = automation),
    do: {:reply, {:error, :active_automation_cannot_be_altered}, automation}

  def handle_call(
        {:add_step_at, step, position},
        _from,
        %{steps: steps, total_steps: total_steps} = automation
      ) do
    index = get_index(steps, position)

    steps = List.insert_at(steps, index, step)
    total_steps = total_steps + 1

    [automation_uuid: automation.uuid, step: step, index: index]
    |> Event.StepAddedAt.new()
    |> notify()

    {:reply, {:ok, step.uuid}, %{automation | steps: steps, total_steps: total_steps}}
  end

  def handle_call(
        {:delete_step, step_uuid},
        _from,
        %{steps: steps, total_steps: total_steps} = automation
      ) do
    automation =
      case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
        nil ->
          automation

        step_index ->
          new_steps = List.delete_at(steps, step_index)
          total_steps = total_steps - 1

          [automation_uuid: automation.uuid, step_uuid: step_uuid]
          |> Event.StepDeleted.new()
          |> notify()

          %{automation | steps: new_steps, total_steps: total_steps}
      end

    {:reply, :ok, automation}
  end

  def handle_call({:rename_step, step_uuid, new_name}, _from, %{steps: steps} = automation) do
    case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
      nil ->
        {:reply, {:error, :no_such_step_exists}, automation}

      step_index ->
        new_steps = List.update_at(steps, step_index, &%{&1 | name: new_name})

        if(Enum.at(new_steps, step_index) != Enum.at(steps, step_index)) do
          [automation_uuid: automation.uuid, step_uuid: step_uuid, name: new_name]
          |> Event.StepRenamed.new()
          |> notify()
        end

        {:reply, :ok, %{automation | steps: new_steps}}
    end
  end

  def handle_call(
        {:move_step_to, step_uuid, position},
        _from,
        %{steps: steps, total_steps: total_steps} = automation
      ) do
    to_index = get_index(steps, position)

    case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
      nil ->
        {:reply, {:error, :no_such_step_exists}, automation}

      step_index
      when step_index == to_index or
             (step_index == total_steps - 1 and to_index == -1) ->
        {:reply, :ok, automation}

      step_index ->
        {step, steps} = List.pop_at(steps, step_index)

        new_steps = List.insert_at(steps, to_index, step)

        [automation_uuid: automation.uuid, step_uuid: step_uuid, index: to_index]
        |> Event.StepMovedTo.new()
        |> notify()

        {:reply, :ok, %{automation | steps: new_steps}}
    end
  end

  def handle_call({:activate_step, step_uuid}, _from, %{steps: steps} = automation) do
    case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
      nil ->
        {:reply, {:error, :no_such_step_exists}, automation}

      step_index ->
        new_steps = List.update_at(steps, step_index, &%{&1 | active: true})

        if(Enum.at(new_steps, step_index) != Enum.at(steps, step_index)) do
          [automation_uuid: automation.uuid, step_uuid: step_uuid]
          |> Event.StepActivated.new()
          |> notify()
        end

        {:reply, :ok, %{automation | steps: new_steps}}
    end
  end

  def handle_call({:deactivate_step, step_uuid}, _from, %{steps: steps} = automation) do
    case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
      nil ->
        {:reply, {:error, :no_such_step_exists}, automation}

      step_index ->
        new_steps = List.update_at(steps, step_index, &%{&1 | active: false})

        if(Enum.at(new_steps, step_index) != Enum.at(steps, step_index)) do
          [automation_uuid: automation.uuid, step_uuid: step_uuid]
          |> Event.StepDeactivated.new()
          |> notify()
        end

        {:reply, :ok, %{automation | steps: new_steps}}
    end
  end

  def handle_info(
        {:waiting_finished, step_uuid},
        %{
          timer: timer,
          timer_ref: step_uuid
        } = automation
      ) do
    stop_timer(timer)

    {:noreply, %{automation | timer: nil, timer_ref: nil}, {:continue, {:finish_step, step_uuid}}}
  end

  def handle_info({:waiting_finished, _step_uuid, _timer_ref}, automation),
    do: {:noreply, automation}

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@automations, event)

  defp get_index(_list, :first), do: 0
  defp get_index(_list, :last), do: -1
  defp get_index(_list, position) when position < 1, do: 0
  defp get_index(list, position) when position > length(list), do: -1
  defp get_index(_list, position), do: position - 1

  defp stop_timer(timer_ref) when is_reference(timer_ref), do: Process.cancel_timer(timer_ref)
  defp stop_timer(_), do: :ok

  defp finish_step(
         current_step_uuid,
         %{
           last_step_index: current_step_index,
           last_step_started_timestamp: step_started_timestamp
         } = automation
       ) do
    step_stopped_timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    [
      automation_uuid: automation.uuid,
      step_uuid: current_step_uuid,
      step_position: current_step_index + 1,
      timestamp: step_stopped_timestamp,
      step_duration: step_stopped_timestamp - step_started_timestamp
    ]
    |> Event.StepStopped.new()
    |> notify()
  end
end
