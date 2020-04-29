defmodule Peasant.Storage.Observer do
  use GenServer, restart: :transient

  alias Peasant.Storage.Keeper

  alias Peasant.Tool.Event, as: Tool
  alias Peasant.Automation.Event, as: Automation

  alias Peasant.Repo

  require Logger

  @tools "tools"
  @automations "automations"

  @tool_to_actions :tta
  @action_to_tools :att

  @default_state %{
    @tools => %{},
    @automations => %{}
  }

  def list(domain), do: Repo.list(domain)

  def get(id, domain), do: Repo.get(id, domain)

  def clear(domain), do: Repo.clear(domain)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe("tools")
    Peasant.subscribe("automations")

    {:ok, @default_state, {:continue, :load}}
  end

  def handle_continue(:load, collection) do
    for domain <- [@tools, @automations] do
      for record <- Repo.list(domain) do
        Repo.put(record, record.uuid, domain)
      end
    end

    {:noreply, collection, {:continue, :populate}}
  end

  def handle_continue(:populate, collection) do
    for tool <- Repo.list(@tools) do
      Peasant.Tool.Handler.register(tool)
    end

    for automation <- Repo.list(@automations) do
      Peasant.Automation.Handler.create(automation)
    end

    {:noreply, collection}
  end

  def handle_call({:list, domain}, _from, collection),
    do: {:reply, collection[domain] |> Map.values(), collection}

  def handle_call({:get, id, domain}, _from, collection),
    do: {:reply, get_in(collection, [domain, id]), collection}

  def handle_call(:clear, _from, _collection),
    do: {:reply, :ok, @default_state}

  ######################### ############
  ######################### Tools domain
  #########################

  def handle_info(%Tool.Registered{details: %{tool: tool}}, collection) do
    maybe_persist(tool, tool.uuid, @tools, collection)

    {:noreply, collection}
  end

  def handle_info(%Tool.Attached{tool_uuid: uuid}, collection) do
    %{Repo.get(uuid, @tools) | attached: true}
    |> maybe_persist(uuid, @tools, collection)

    {:noreply, collection}
  end

  #########################
  ######################### Tools domain
  ######################### ############

  ######################### ##################
  ######################### Automations domain
  #########################

  def handle_info(%Automation.Created{automation: automation}, collection) do
    maybe_persist(automation, automation.uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Activated{automation_uuid: uuid},
        collection
      ) do
    %{Repo.get(uuid, @automations) | active: true}
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Deactivated{automation_uuid: uuid},
        collection
      ) do
    %{Repo.get(uuid, @automations) | active: false}
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Renamed{automation_uuid: uuid, name: name},
        collection
      ) do
    %{Repo.get(uuid, @automations) | name: name}
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepAddedAt{automation_uuid: uuid, step: step, index: index},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&List.insert_at(&1, index, step))
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepActivated{automation_uuid: uuid, step_uuid: step_uuid},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: true} end))
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDeactivated{automation_uuid: uuid, step_uuid: step_uuid},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: false} end))
    |> maybe_persist(uuid, @automations, collection)

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
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepRenamed{automation_uuid: uuid, step_uuid: step_uuid, name: name},
        collection
      ) do
    uuid
    |> Repo.get(@automations)
    |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | name: name} end))
    |> maybe_persist(uuid, @automations, collection)

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
    |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  #########################
  ######################### Automations domain
  ######################### ##################

  # pass all other events
  def handle_info(_, collection), do: {:noreply, collection}

  defp maybe_persist(entity, entity_id, domain, collection) do
    entity_id
    |> Repo.get(domain)
    |> case do
      {:error, _} = error -> raise "Something happened with repo: #{inspect(error)}"
      ^entity -> :ok
      _ -> Repo.put(entity, entity_id, domain)
    end

    collection
    |> Map.get(domain)
    |> Map.get(entity_id)
    |> case do
      ^entity ->
        collection

      _ ->
        entity = Repo.get(entity_id, domain)
        update_in(collection, [domain, entity_id], fn _ -> entity end)
    end
  end

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
