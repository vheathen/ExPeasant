defmodule Peasant.Automation.Handler do
  use GenServer

  @domain "automations"

  alias Peasant.Automation.State
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

  def add_step_at(automation_uuid, step, position),
    do: try_action(automation_uuid, {:add_step_at, step, position})

  def delete_step(automation_uuid, step_uuid),
    do: try_action(automation_uuid, {:delete_step, step_uuid})

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

  def init(%State{new: true} = automation) do
    {:ok, %{automation | new: false}, {:continue, :created}}
  end

  def handle_continue(:created, automation) do
    [automation_uuid: automation.uuid, automation: automation]
    |> Peasant.Automation.Event.Created.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_call({:rename, new_name}, _from, %{name: new_name} = automation),
    do: {:reply, :ok, automation}

  def handle_call({:rename, new_name}, _from, automation) do
    [automation_uuid: automation.uuid, name: new_name]
    |> Event.Renamed.new()
    |> notify()

    {:reply, :ok, %{automation | name: new_name}}
  end

  #
  # step operations
  #

  def handle_call(_, _from, %{active: true} = automation),
    do: {:reply, {:error, :active_automation_cannot_be_altered}, automation}

  def handle_call({:add_step_at, step, position}, _from, %{steps: steps} = automation) do
    index = get_index(steps, position)

    steps = List.insert_at(steps, index, step)

    [automation_uuid: automation.uuid, step: step, index: index]
    |> Event.StepAddedAt.new()
    |> notify()

    {:reply, :ok, %{automation | steps: steps}}
  end

  def handle_call({:delete_step, step_uuid}, _from, %{steps: steps} = automation) do
    automation =
      case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
        nil ->
          automation

        step_index ->
          new_steps = List.delete_at(steps, step_index)

          [automation_uuid: automation.uuid, step_uuid: step_uuid]
          |> Event.StepDeleted.new()
          |> notify()

          %{automation | steps: new_steps}
      end

    {:reply, :ok, automation}
  end

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@domain, event)

  defp get_index(_list, :first), do: 0
  defp get_index(_list, :last), do: -1
  defp get_index(_list, position) when position < 1, do: 0
  defp get_index(list, position) when position > length(list), do: -1
  defp get_index(_list, position), do: position - 1
end
