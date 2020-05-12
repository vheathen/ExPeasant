defmodule PeasantWeb.StepEditLiveComponent do
  use PeasantWeb, :live_component

  import PeasantWeb.AutomationsHelpers
  import PeasantWeb.ToolsHelpers

  @impl true
  def update(%{step: step} = assigns, socket) do
    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(
        changeset: Peasant.Automations.change_automation_step(step),
        form_disabled: false
      )
      |> parse_step()
    }
  end

  @impl true
  def handle_event("validate", %{"step" => step_params}, socket) do
    require Logger
    Logger.debug(inspect(step_params))

    changeset =
      socket.assigns.step
      |> Peasant.Automations.change_automation_step(step_params)
      |> Map.put(:action, :insert)

    {
      :noreply,
      socket
      |> assign(changeset: changeset)
      |> parse_step()
    }
  end

  def handle_event("save", %{"step" => step}, socket) do
    {:noreply, save_step(socket, step)}
  end

  defp save_step(%{assigns: %{step: %{uuid: nil}}} = socket, step) do
    case Peasant.Automation.add_step_at(
           socket.assigns.automation_uuid,
           step,
           socket.assigns.position
         ) do
      {:ok, _step_uuid} ->
        socket
        |> put_flash(:success, "A new step added at #{socket.assigns.position} position")
        |> push_patch(to: socket.assigns.return_to)

      {:error, errors} ->
        assign(
          socket,
          changeset: %{socket.assigns.changeset | errors: errors, valid?: false, action: :insert}
        )
    end
  end

  defp save_step(%{assigns: %{step: %{uuid: current_step_uuid}}} = socket, step) do
    case Peasant.Automation.add_step_at(
           socket.assigns.automation_uuid,
           step,
           socket.assigns.position
         ) do
      {:ok, _step_uuid} ->
        Peasant.Automation.delete_step(socket.assigns.automation_uuid, current_step_uuid)

        socket
        |> put_flash(:success, "Step # #{socket.assigns.position} updated")
        |> push_patch(to: socket.assigns.return_to)

      {:error, errors} ->
        assign(
          socket,
          changeset: %{socket.assigns.changeset | errors: errors, valid?: false, action: :insert}
        )
    end
  end

  defp parse_step(socket) do
    assign(
      socket,
      [:type, :tool_uuid, :action, :action_config]
      |> Enum.map(fn key ->
        {key, Ecto.Changeset.fetch_field!(socket.assigns.changeset, key)}
      end)
    )
  end

  # defp save_user(socket, :edit, user_params) do
  #   case Accounts.update_user(socket.assigns.user, user_params) do
  #     {:ok, _user} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "User updated successfully")
  #        |> push_redirect(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, :changeset, changeset)}
  #   end
  # end

  # defp save_user(socket, :new, user_params) do
  #   case Accounts.create_user(user_params) do
  #     {:ok, _user} ->
  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "User created successfully")
  #        |> push_redirect(to: socket.assigns.return_to)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, changeset: changeset)}
  #   end
  # end
end
