defmodule Peasant.Storage.Observer do
  use GenServer

  alias Peasant.Repo

  alias Peasant.Tool.Event.{
    Registered,
    Attached
  }

  @tools "tools"

  @default_state %{
    @tools => %{}
  }

  def list(domain), do: GenServer.call(__MODULE__, {:list, domain})

  def clear, do: GenServer.call(__MODULE__, :clear)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe("tools")

    {:ok, @default_state, {:continue, :load}}
  end

  def handle_continue(:load, objects) do
    objects =
      Repo.get_all()
      |> Enum.reduce(objects, fn
        {_key, {domain, record}}, objs ->
          update_in(objs, [domain, record.uuid], fn _ -> record end)

        _, objs ->
          objs
      end)

    {:noreply, objects, {:continue, :populate}}
  end

  def handle_continue(:populate, objects) do
    objects
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

      some ->
        require Logger
        Logger.warn(inspect(some))
        :ok
    end)

    {:noreply, objects}
  end

  def handle_call({:list, domain}, _from, objects) do
    {:reply, objects[domain] |> Map.values(), objects}
  end

  def handle_call(:clear, _from, _objects) do
    {:reply, :ok, @default_state}
  end

  def handle_info(%Registered{details: %{tool: tool}}, %{@tools => tools} = objects) do
    objects =
      case Map.get(tools, tool.uuid) do
        ^tool ->
          objects

        _ ->
          tool = Repo.persist(tool, @tools)
          update_in(objects, [@tools, tool.uuid], fn _ -> tool end)
      end

    {:noreply, objects}
  end

  def handle_info(%Attached{tool_uuid: uuid}, %{@tools => tools} = objects) do
    objects =
      case Map.get(tools, uuid) do
        %{attached: true} ->
          objects

        %{attached: false} = tool ->
          tool = Repo.persist(%{tool | attached: true}, @tools)
          update_in(objects, [@tools, uuid], fn _ -> tool end)
      end

    {:noreply, objects}
  end

  # pass all other events
  def handle_info(_, objects) do
    {:noreply, objects}
  end
end
