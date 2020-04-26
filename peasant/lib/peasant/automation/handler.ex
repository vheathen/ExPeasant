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

  def rename_step(automation_uuid, step_uuid, new_name),
    do: try_action(automation_uuid, {:rename_step, step_uuid, new_name})

  def move_step_to(automation_uuid, step_uuid, position),
    do: try_action(automation_uuid, {:move_step_to, step_uuid, position})

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

  def handle_call({:move_step_to, step_uuid, position}, _from, %{steps: steps} = automation) do
    to_index = get_index(steps, position)
    steps_count = length(steps)

    case Enum.find_index(steps, &(&1.uuid == step_uuid)) do
      nil ->
        {:reply, {:error, :no_such_step_exists}, automation}

      step_index
      when step_index == to_index or
             (step_index == steps_count - 1 and to_index == -1) ->
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

  defp notify(events) when is_list(events), do: Enum.each(events, &notify/1)
  defp notify(event), do: Peasant.broadcast(@domain, event)

  defp get_index(_list, :first), do: 0
  defp get_index(_list, :last), do: -1
  defp get_index(_list, position) when position < 1, do: 0
  defp get_index(list, position) when position > length(list), do: -1
  defp get_index(_list, position), do: position - 1
end
