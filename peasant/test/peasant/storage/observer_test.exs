defmodule Peasant.Storage.ObserverTest do
  use Peasant.DataCase

  alias Peasant.Repo

  @observer Peasant.Storage.Observer

  describe "Observer" do
    @describetag :integration

    test "should be started" do
      assert is_pid(GenServer.whereis(@observer))
    end
  end

  describe "on Registered event" do
    @describetag :integration

    alias Peasant.Tools.FakeTool

    alias Peasant.Tool.Event.{
      Registered,
      Attached
    }

    setup do
      %type{uuid: uuid} = tool = new_tool() |> FakeTool.new()
      event = Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})

      db = Repo.db()

      assert is_nil(CubDB.get(db, uuid))
      assert is_nil(CubDB.get(db, {"tools", type, uuid}))

      notify(event)

      Process.sleep(100)

      [tool: tool, db: db]
    end

    test "should persist a tool record on Registered event", %{
      tool: %type{uuid: uuid},
      db: db
    } do
      assert {"tools", %^type{uuid: ^uuid}} = CubDB.get(db, uuid)
      assert true == CubDB.get(db, {"tools", type, uuid})
    end

    test "should persist a tool record on Attached event", %{
      tool: %{uuid: uuid},
      db: db
    } do
      event = Attached.new(tool_uuid: uuid)

      notify(event)

      Process.sleep(100)

      assert {"tools", %{uuid: ^uuid, attached: true}} = CubDB.get(db, uuid)
    end
  end

  defp notify(event), do: Peasant.broadcast("tools", event)
end
