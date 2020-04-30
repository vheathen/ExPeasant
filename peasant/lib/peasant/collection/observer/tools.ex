defmodule Peasant.Collection.Observer.Tools do
  use GenServer, restart: :transient

  alias Peasant.Tool.Event, as: Tool

  alias Peasant.Repo

  @tools Peasant.Tool.domain()

  @default_state %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Peasant.subscribe(@tools)

    {:ok, @default_state}
  end

  ######################### ############
  ######################### Tools domain
  #########################

  def handle_info(%Tool.Registered{details: %{tool: tool}}, collection) do
    Repo.maybe_persist(tool, tool.uuid, @tools)

    {:noreply, collection}
  end

  def handle_info(%Tool.Attached{tool_uuid: uuid}, collection) do
    %{Repo.get(uuid, @tools) | attached: true}
    |> Repo.maybe_persist(uuid, @tools)

    {:noreply, collection}
  end

  #########################
  ######################### Tools domain
  ######################### ############

  # pass all other events
  def handle_info(_, collection), do: {:noreply, collection}
end
