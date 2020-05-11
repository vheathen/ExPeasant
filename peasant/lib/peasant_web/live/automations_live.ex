defmodule PeasantWeb.AutomationsLive do
  use PeasantWeb, :live_view

  import PeasantWeb.TableHelpers
  import PeasantWeb.LiveHelpers

  import PeasantWeb.AutomationsHelpers

  alias Peasant.Automation.Event, as: Automation

  @automations Peasant.Tool.domain()

  @sort_by ~w(updated_at name active)

  @active_color %{
    true => "green",
    false => "dark-gray"
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      Phoenix.LiveView.assign(socket, :menu, %{
        action: socket.assigns.live_action
      })

    Peasant.subscribe(@automations)

    {:ok, assign(socket, params: %{})}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {
      :noreply,
      socket
      |> assign_params(params, @sort_by)
      |> fetch_automations()
    }
  end

  defp fetch_automations(socket) do
    %{
      search: search,
      sort_by: sort_by,
      sort_dir: sort_dir,
      limit: limit,
      offset: offset
    } = socket.assigns.params

    {automations, total} = list_automations(search, sort_by, sort_dir, limit, offset)

    assign(socket, automations: automations, total: total)
  end

  @impl true
  def handle_info(%Automation.Created{}, socket),
    do: {:noreply, fetch_automations(socket)}

  def handle_info(%Automation.Activated{automation_uuid: uuid}, socket) do
    tools =
      socket.assigns.automations
      |> update_automation(uuid, &%{&1 | active: true})

    {:noreply, assign(socket, tools: tools)}
  end

  def handle_info(:refresh, socket) do
    {:noreply, fetch_automations(socket)}
  end

  @impl true
  def handle_event("select_limit", %{"limit" => limit}, socket) do
    %{params: params} = socket.assigns
    {:noreply, push_patch(socket, to: self_path(socket, %{params | limit: limit}))}
  end

  def handle_event("go_to_automation", %{"uuid" => uuid}, socket) do
    {:noreply, push_redirect(socket, to: live_peasant_path(socket, :automation, [uuid]))}
  end

  defp self_path(socket, params) do
    live_peasant_path(socket, :automations, [], params)
  end

  defp active_color(state), do: @active_color[state]

  defp update_automation(automations, uuid, fun) do
    case Enum.find_index(automations, &(&1.uuid == uuid)) do
      nil -> automations
      index -> List.update_at(automations, index, fun)
    end
  end
end
