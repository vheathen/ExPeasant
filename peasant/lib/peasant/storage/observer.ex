defmodule Peasant.Storage.Observer do
  use GenServer

  alias Peasant.Repo

  alias Peasant.Tool.Event.{
    Registered,
    Attached
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe("tools")

    {:ok, %{}}
  end

  def handle_info(%Registered{details: %{tool: tool}}, objects) do
    objects =
      case Map.get(objects, tool.uuid) do
        ^tool ->
          objects

        _ ->
          tool = Repo.persist(tool, "tools")
          Map.put(objects, tool.uuid, tool)
      end

    {:noreply, objects}
  end

  def handle_info(%Attached{tool_uuid: uuid}, objects) do
    objects =
      case Map.get(objects, uuid) do
        %{attached: true} ->
          objects

        %{attached: false} = tool ->
          tool = Repo.persist(%{tool | attached: true}, "tools")
          Map.put(objects, tool.uuid, tool)
      end

    {:noreply, objects}
  end

  # pass all other events
  def handle_info(_, objects) do
    {:noreply, objects}
  end
end
