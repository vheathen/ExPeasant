defmodule PeasantWeb.AutomationLiveEdit do
  use PeasantWeb, :live_component

  def update(%{automation: automation} = assigns, socket) do
    changeset = Peasant.Automations.change_automation(automation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"automation" => automation}, socket) do
    changeset =
      socket.assigns.automation
      |> Peasant.Automations.change_automation(automation)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"automation" => automation}, socket) do
    save_automation(socket, automation)
  end

  defp save_automation(%{assigns: %{automation: %{uuid: nil}}}, automation) do
    case Peasant.Automation.create(automation) do
      {:ok, automation_uuid} ->
        true

      {:error, errors} ->
        true
    end
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
