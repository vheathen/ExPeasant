defmodule Peasant.Storage.Observer do
  use GenServer, restart: :transient

  alias Peasant.Storage.Keeper

  alias Peasant.Tool.Event, as: Tool
  alias Peasant.Automation.Event, as: Automation

  @tools "tools"
  @automations "automations"

  @default_state %{
    @tools => %{},
    @automations => %{}
  }

  def list(domain), do: GenServer.call(__MODULE__, {:list, domain})

  def get(id, domain), do: GenServer.call(__MODULE__, {:get, id, domain})

  def clear, do: GenServer.call(__MODULE__, :clear)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe("tools")
    Peasant.subscribe("automations")

    {:ok, @default_state, {:continue, :load}}
  end

  def handle_continue(:load, collection) do
    collection =
      Keeper.get_all()
      |> Enum.reduce(collection, fn
        {_key, {domain, record}}, objs ->
          update_in(objs, [domain, record.uuid], fn _ -> record end)

        _, objs ->
          objs
      end)

    {:noreply, collection, {:continue, :populate}}
  end

  def handle_continue(:populate, collection) do
    collection
    |> Enum.to_list()
    |> Enum.reduce([], fn
      {domain, records}, flat_list ->
        Enum.reduce(
          records,
          flat_list,
          fn {_, record}, list -> [{domain, record} | list] end
        )

      _, flat_list ->
        flat_list
    end)
    |> Enum.each(fn
      {@tools, %{uuid: _} = record} ->
        Peasant.Tool.Handler.register(record)

      {@automations, %{uuid: _} = record} ->
        Peasant.Automation.Handler.create(record)

      some ->
        require Logger
        Logger.warn(inspect(some))
        :ok
    end)

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
    collection = maybe_persist(tool, tool.uuid, @tools, collection)

    {:noreply, collection}
  end

  def handle_info(%Tool.Attached{tool_uuid: uuid}, %{@tools => tools} = collection) do
    collection =
      %{Map.get(tools, uuid) | attached: true}
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
    collection = maybe_persist(automation, automation.uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Activated{automation_uuid: uuid},
        %{@automations => automations} = collection
      ) do
    collection =
      %{Map.get(automations, uuid) | active: true}
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Deactivated{automation_uuid: uuid},
        %{@automations => automations} = collection
      ) do
    collection =
      %{Map.get(automations, uuid) | active: false}
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.Renamed{automation_uuid: uuid, name: name},
        %{@automations => automations} = collection
      ) do
    collection =
      %{Map.get(automations, uuid) | name: name}
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepAddedAt{automation_uuid: uuid, step: step, index: index},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
      |> update_steps(&List.insert_at(&1, index, step))
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepActivated{automation_uuid: uuid, step_uuid: step_uuid},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
      |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: true} end))
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDeactivated{automation_uuid: uuid, step_uuid: step_uuid},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
      |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | active: false} end))
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepDeleted{automation_uuid: uuid, step_uuid: step_uuid},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
      |> update_steps(
        &List.delete_at(&1, Enum.find_index(&1, fn step -> step.uuid == step_uuid end))
      )
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepRenamed{automation_uuid: uuid, step_uuid: step_uuid, name: name},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
      |> update_steps(&update_step(&1, step_uuid, fn step -> %{step | name: name} end))
      |> maybe_persist(uuid, @automations, collection)

    {:noreply, collection}
  end

  def handle_info(
        %Automation.StepMovedTo{automation_uuid: uuid, step_uuid: step_uuid, index: index},
        %{@automations => automations} = collection
      ) do
    collection =
      automations
      |> Map.get(uuid)
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
    collection
    |> Map.get(domain)
    |> Map.get(entity_id)
    |> case do
      ^entity ->
        collection

      _ ->
        entity = Keeper.persist(entity, domain)
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
