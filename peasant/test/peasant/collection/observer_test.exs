defmodule Peasant.Collection.ObserverTest do
  use Peasant.GeneralCase

  import Peasant.Collection.TestHelper

  alias Peasant.Repo
  alias Peasant.Collection.Keeper

  @observer Peasant.Collection.Observer

  @tools Peasant.Tool.domain()
  @automations Peasant.Automation.domain()

  setup do
    Peasant.subscribe(@tools)
    Peasant.subscribe(@automations)

    assert is_pid(GenServer.whereis(@observer))

    [db: Keeper.db()]
  end

  describe "Observer" do
    @describetag :integration

    Peasant.subscribe(@tools)
    Peasant.subscribe(@automations)

    test "should be started", do: :ok
  end

  describe "on start" do
    @describetag :integration

    setup [:collection_setup, :on_start_collection_setup]

    test "it should load all records", %{tools: tools, automations: automations} do
      assert tools == Repo.list(@tools) |> Enum.sort()
      assert automations == Repo.list(@automations) |> Enum.sort()
    end

    test "it should populate all tools", %{tools: tools} do
      Enum.each(tools, fn %{uuid: uuid} ->
        assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)

        assert is_pid(pid)
      end)
    end

    test "it should populate all automations", %{automations: automations} do
      Enum.each(automations, fn %{uuid: uuid} ->
        assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)

        assert is_pid(pid)
      end)
    end
  end

  test "it should populate all tools and actions" do
    for {_action, _tools} <- Peasant.Tools.actions() do
    end
  end

  describe "current_state/0" do
    @describetag :integration

    test "should return current state: :loading or :ready" do
      assert @observer.current_state() in [:loading, :ready]
    end
  end
end
