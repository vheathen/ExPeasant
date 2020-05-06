defmodule Peasant.Collection.Observer.Automations do
  use GenServer, restart: :transient

  alias Peasant.Automation.Event, as: Automation

  alias Peasant.Repo

  require Logger

  @automations Peasant.Automation.domain()

  @default_state %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe(@automations)

    {:ok, @default_state}
  end

  def handle_info(%Automation.Created{automation: automation}, collection) do
    Repo.maybe_persist(automation, automation.uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Activated{automation_uuid: uuid},
        collection
      ) do
    %{Repo.get(uuid, @automations) | active: true}
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Deactivated{automation_uuid: uuid},
        collection
      ) do
    %{Repo.get(uuid, @automations) | active: false}
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Renamed{automation_uuid: uuid, name: name},
        collection
      ) do
    %{Repo.get(uuid, @automations) | name: name}
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepAddedAt{automation_uuid: uuid, step: step, index: index},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&List.insert_at(&1, index, step))
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepActivated{automation_uuid: uuid, step_uuid: step_uuid},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: true} end))
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDeactivated{automation_uuid: uuid, step_uuid: step_uuid},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: false} end))
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDeleted{automation_uuid: uuid, step_uuid: step_uuid},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(
      &List.delete_at(&1, Enum.find_index(&1, fn step -> step.uuid == step_uuid end))
    )
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDescriptionChanged{
          automation_uuid: uuid,
          step_uuid: step_uuid,
          description: description
        },
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(
      &update_step(&1, step_uuid, fn step -> %{step | description: description} end)
    )
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepMovedTo{automation_uuid: uuid, step_uuid: step_uuid, index: index},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(fn steps ->
      step = Enum.find(steps, &(&1.uuid == step_uuid))

      steps
      |> List.delete(step)
      |> List.insert_at(index, step)
    end)
    |> Repo.maybe_persist(uuid, @automations)

    {:noreply, collection}
  end

  # pass all other events
  def handle_info(_, collection), do: {:noreply, collection}

  defp update_step(steps, step_uuid, fun) when is_function(fun, 1) do
    List.update_at(
      steps,
      Enum.find_index(steps, fn step -> step.uuid == step_uuid end),
      &fun.(&1)
    )
  end

  defp update_steps(automation, fun) when is_function(fun, 1) do
    Map.update(
      automation,
      :steps,
      [],
      &fun.(&1)
    )
  end
end
