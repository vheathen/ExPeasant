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

  def change_step_description(automation_uuid, step_uuid, new_description),
    do: try_action(automation_uuid, {:change_step_description, step_uuid, new_description})

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
    do: {:ok, %{automation | new: false}, {:continue, {:persist, :created}}}

  def init(%State{} = automation),
    do: {:ok, automation, {:continue, :loaded}}

  def handle_continue(:persist, automation), do: handle_continue({:persist, nil}, automation)

  def handle_continue({:persist, next_action}, automation) do
    automation = Peasant.Repo.put(automation, automation.uuid, @automations)

    if is_nil(next_action),
      do: {:noreply, automation},
      else: {:noreply, automation, {:continue, next_action}}
  end

  def handle_continue(:cache_till_reboot, automation),
    do: handle_continue({:cache_till_reboot, nil}, automation)

  def handle_continue({:cache_till_reboot, next_action}, automation) do
    automation = Peasant.Repo.put(automation, automation.uuid, @automations, persist: false)

    if is_nil(next_action),
      do: {:noreply, automation},
      else: {:noreply, automation, {:continue, next_action}}
  end

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
        :renamed,
        automation
      ) do
    [automation_uuid: automation.uuid, name: automation.name]
    |> Event.Renamed.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_added_at, step, index},
        automation
      ) do
    [automation_uuid: automation.uuid, step: step, index: index]
    |> Event.StepAddedAt.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_deleted, step_uuid},
        automation
      ) do
    [automation_uuid: automation.uuid, step_uuid: step_uuid]
    |> Event.StepDeleted.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_description_changed, step_uuid, new_description},
        automation
      ) do
    [automation_uuid: automation.uuid, step_uuid: step_uuid, description: new_description]
    |> Event.StepDescriptionChanged.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_moved_to, step_uuid, index},
        automation
      ) do
    [automation_uuid: automation.uuid, step_uuid: step_uuid, index: index]
    |> Event.StepMovedTo.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_activated, step_uuid},
        automation
      ) do
    [automation_uuid: automation.uuid, step_uuid: step_uuid]
    |> Event.StepActivated.new()
    |> notify()

    {:noreply, automation}
  end

  def handle_continue(
        {:step_deactivated, step_uuid},
        automation
      ) do
    [automation_uuid: automation.uuid, step_uuid: step_uuid]
    |> Event.StepDeactivated.new()
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
      | last_step_index: current_step_index,
        last_step_attempted_at: now()
    }

    {
      :noreply,
      automation,
      {:continue, {:cache_till_reboot, {:maybe_start_step, current_step}}}
    }
  end

  def handle_continue({:maybe_start_step, %Step{active: false} = current_step}, automation),
    do: {:noreply, automation, {:continue, {:step_skipped, current_step}}}

  def handle_continue({:maybe_start_step, current_step}, automation),
    do: {:noreply, automation, {:continue, {:step_started, current_step}}}

  # def handle_continue({:maybe_start_step, _current_step}, %{active: false} = automation),
  #   do: {:noreply, automation}

  def handle_continue(
        {:step_skipped, current_step},
        automation
      ) do
    [
      automation_uuid: automation.uuid,
      step_uuid: current_step.uuid,
      index: automation.last_step_index,
      timestamp: automation.last_step_attempted_at
    ]
    |> Event.StepSkipped.new()
    |> notify()

    Process.send(self(), :next_step, [])

    {:noreply, automation}
  end

  def handle_continue(
        {:step_started, current_step},
        automation
      ) do
    [
      automation_uuid: automation.uuid,
      step_uuid: current_step.uuid,
      index: automation.last_step_index,
      timestamp: automation.last_step_attempted_at
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
      # Cover case with tests

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

    Process.send(self(), :next_step, [])

    {:noreply, automation}
  end

  def handle_continue(
        {:fail_step, current_step_uuid, error},
        %{
          last_step_index: current_step_index,
          last_step_attempted_at: step_started_timestamp
        } = automation
      ) do
    step_stopped_timestamp = now()

    [
      automation_uuid: automation.uuid,
      step_uuid: current_step_uuid,
      index: current_step_index,
      timestamp: step_stopped_timestamp,
      step_duration: step_stopped_timestamp - step_started_timestamp,
      details: error
    ]
    |> Event.StepFailed.new()
    |> notify()

    Process.send(self(), :next_step, [])

    {:noreply, automation}
  end

  def handle_call({:rename, new_name}, _from, %{name: new_name} = automation),
    do: {:reply, :ok, automation}

  def handle_call({:rename, new_name}, _from, automation) do
    {:reply, :ok, %{automation | name: new_name}, {:continue, {:persist, :renamed}}}
  end

  def handle_call(:activate, _from, %{active: true} = automation),
    do: {:reply, :ok, automation}

  def handle_call(:activate, _from, %{steps: []} = automation),
    do: {:reply, {:error, "automation doesn't contain any steps"}, automation}

  def handle_call(:activate, _from, automation),
    do: {:reply, :ok, %{automation | active: true}, {:continue, {:persist, :activated}}}

  def handle_call(:deactivate, _from, %{active: false} = automation),
    do: {:reply, :ok, automation}

  def handle_call(:deactivate, _from, automation),
    do: {:reply, :ok, %{automation | active: false}, {:continue, {:persist, :deactivated}}}

  #
  # step operations
  #

  def handle_call(_, _from, %{active: true} = automation),
    do: {:reply, {:error, :active_automation_cannot_be_altered}, automation}

  def handle_call(
        {:add_step_at, step, position},
        _from,
        automation
      ) do
    index = get_index(automation.steps, position)
    steps = List.insert_at(automation.steps, index, step)

    {
      :reply,
      {:ok, step.uuid},
      %{automation | steps: steps, total_steps: automation.total_steps + 1},
      {:continue, {:persist, {:step_added_at, step, index}}}
    }
  end

  def handle_call(
        {:delete_step, step_uuid},
        _from,
        automation
      ) do
    case _update_steps(automation, &_delete_step(&1, step_uuid)) do
      ^automation ->
        {:reply, :ok, automation}

      %{} = new_automation ->
        {:reply, :ok, %{new_automation | total_steps: automation.total_steps - 1},
         {:continue, {:persist, {:step_deleted, step_uuid}}}}
    end
  end

  def handle_call({:change_step_description, step_uuid, new_description}, _from, automation) do
    change_description = &%{&1 | description: new_description}

    case _update_steps(automation, &_update_step(&1, step_uuid, change_description, true)) do
      %{steps: nil} ->
        {:reply, {:error, :no_such_step_exists}, automation}

      ^automation ->
        {:reply, :ok, automation}

      %{} = automation ->
        {:reply, :ok, automation,
         {:continue, {:persist, {:step_description_changed, step_uuid, new_description}}}}
    end
  end

  def handle_call(
        {:move_step_to, step_uuid, position},
        _from,
        automation
      ) do
    to_index = get_index(automation.steps, position)
    from_index = _step_index(automation.steps, step_uuid)

    move =
      &case from_index && List.pop_at(&1, from_index) do
        nil -> nil
        {step, steps} -> List.insert_at(steps, to_index, step)
      end

    case _update_steps(automation, move) do
      %{steps: nil} ->
        {:reply, {:error, :no_such_step_exists}, automation}

      ^automation ->
        {:reply, :ok, automation}

      %{} = automation ->
        {
          :reply,
          :ok,
          automation,
          {:continue, {:persist, {:step_moved_to, step_uuid, to_index}}}
        }
    end
  end

  def handle_call(
        {:activate_step, step_uuid},
        _from,
        automation
      ) do
    activate = &%{&1 | active: true}

    case _update_steps(automation, &_update_step(&1, step_uuid, activate, true)) do
      %{steps: nil} ->
        {:reply, {:error, :no_such_step_exists}, automation}

      ^automation ->
        {:reply, :ok, automation}

      %{} = automation ->
        {
          :reply,
          :ok,
          automation,
          {:continue, {:persist, {:step_activated, step_uuid}}}
        }
    end
  end

  def handle_call({:deactivate_step, step_uuid}, _from, automation) do
    deactivate = &%{&1 | active: false}

    case _update_steps(automation, &_update_step(&1, step_uuid, deactivate, true)) do
      %{steps: nil} ->
        {:reply, {:error, :no_such_step_exists}, automation}

      ^automation ->
        {:reply, :ok, automation}

      %{} = automation ->
        {
          :reply,
          :ok,
          automation,
          {:continue, {:persist, {:step_deactivated, step_uuid}}}
        }
    end
  end

  def handle_info(:next_step, automation), do: {:noreply, automation, {:continue, :next_step}}

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
           last_step_attempted_at: step_started_timestamp
         } = automation
       ) do
    step_stopped_timestamp = now()

    [
      automation_uuid: automation.uuid,
      step_uuid: current_step_uuid,
      index: current_step_index,
      timestamp: step_stopped_timestamp,
      step_duration: step_stopped_timestamp - step_started_timestamp
    ]
    |> Event.StepStopped.new()
    |> notify()
  end

  defp _update_step(steps, step_uuid, fun, nilify? \\ false)

  defp _update_step(steps, step_uuid, fun, false) when is_function(fun, 1),
    do: _update_step(steps, step_uuid, fun, true) || steps

  defp _update_step(steps, step_uuid, fun, true) when is_function(fun, 1) do
    index = _step_index(steps, step_uuid)
    index && List.update_at(steps, index, &fun.(&1))
  end

  defp _delete_step(steps, step_uuid, nilify? \\ false)

  defp _delete_step(steps, step_uuid, false),
    do: _delete_step(steps, step_uuid, true) || steps

  defp _delete_step(steps, step_uuid, true) do
    index = _step_index(steps, step_uuid)
    index && List.delete_at(steps, index)
  end

  defp _step_index(steps, step_uuid), do: Enum.find_index(steps, &(&1.uuid == step_uuid))

  defp _update_steps(automation, fun) when is_function(fun, 1) do
    Map.update(
      automation,
      :steps,
      [],
      &fun.(&1)
    )
  end
end
