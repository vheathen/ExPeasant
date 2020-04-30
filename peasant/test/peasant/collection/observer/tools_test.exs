defmodule Peasant.Collection.Observer.ToolsTest do
  use Peasant.GeneralCase

  import Peasant.Collection.TestHelper

  alias Peasant.Collection.Keeper

  @observer Peasant.Collection.Observer.Tools

  @tools Peasant.Tool.domain()

  setup do
    Peasant.subscribe(@tools)

    assert is_pid(GenServer.whereis(@observer))

    [db: Keeper.db()]
  end

  describe "Tools Observer" do
    @describetag :integration

    test "should be started", do: :ok
  end

  describe "on Tool.Registered event" do
    @describetag :integration

    setup :tool_registered_setup

    test "should persist a tool record on Registered event", %{
      tool: %type{uuid: uuid},
      db: db
    } do
      assert {@tools, %^type{uuid: ^uuid}} = CubDB.get(db, uuid)
      assert true == CubDB.get(db, {@tools, type, uuid})
    end
  end

  describe "on Tool.Attached event" do
    @describetag :integration

    setup [:tool_registered_setup, :tool_attached_setup]

    test "should persist a tool record on Attached event", %{
      tool: %{uuid: uuid},
      db: db
    } do
      assert {@tools, %{uuid: ^uuid, attached: true}} = CubDB.get(db, uuid)
    end
  end
end
