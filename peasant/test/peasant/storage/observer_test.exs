defmodule Peasant.Storage.ObserverTest do
  use Peasant.DataCase

  alias Peasant.Repo

  alias Peasant.Tools.FakeTool

  alias Peasant.Tool.Event.{
    Registered,
    Attached
  }

  alias Peasant.Storage.Observer

  @observer Peasant.Storage.Observer

  setup do
    [db: Repo.db()]
  end

  describe "Observer" do
    @describetag :integration

    test "should be started" do
      assert is_pid(GenServer.whereis(@observer))
    end
  end

  describe "on Registered event" do
    @describetag :integration

    setup :registered_setup

    test "should persist a tool record on Registered event", %{
      tool: %type{uuid: uuid},
      db: db
    } do
      assert {"tools", %^type{uuid: ^uuid}} = CubDB.get(db, uuid)
      assert true == CubDB.get(db, {"tools", type, uuid})
    end
  end

  describe "on Attached event" do
    @describetag :integration

    setup [:registered_setup, :attached_setup]

    test "should persist a tool record on Attached event", %{
      tool: %{uuid: uuid},
      db: db
    } do
      assert {"tools", %{uuid: ^uuid, attached: true}} = CubDB.get(db, uuid)
    end
  end

  describe "list(domain) function" do
    @describetag :integration

    setup :list_setup

    test "should list all objects for the specified domain", %{list: list} do
      assert list == Observer.list("tools") |> nilify_timestamps() |> Enum.sort()
    end
  end

  describe "clear/0" do
    @describetag :integration

    test "should clear all records" do
      :ok = Observer.clear()
      assert [] == Observer.list("tools")
    end
  end

  describe "on start" do
    @describetag :integration

    setup :list_setup

    test "it should load all records", %{list: list} do
      assert list == Observer.list("tools") |> nilify_timestamps() |> Enum.sort()
    end

    test "it should populate all records", %{list: list} do
      Enum.each(list, fn %{uuid: uuid} ->
        assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)
        assert is_pid(pid)
      end)
    end
  end

  def registered_setup(%{db: db}) do
    %type{uuid: uuid} = tool = new_tool() |> FakeTool.new() |> Map.put(:new, false)
    event = Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})

    assert is_nil(CubDB.get(db, uuid))
    assert is_nil(CubDB.get(db, {"tools", type, uuid}))

    notify(event)

    Process.sleep(100)

    [tool: tool]
  end

  def attached_setup(%{tool: %{uuid: uuid}}) do
    event = Attached.new(tool_uuid: uuid)

    notify(event)
    Process.sleep(100)

    :ok
  end

  def list_setup(context) do
    [tool: tool1] = registered_setup(context)
    [tool: tool2] = registered_setup(context)

    list = [tool1, tool2] |> Enum.sort()

    assert list == Observer.list("tools") |> nilify_timestamps() |> Enum.sort()
    GenServer.stop(Observer)
    Process.sleep(100)

    [list: list]
  end

  defp notify(event), do: Peasant.broadcast("tools", event)

  defp nilify_timestamps(records) when is_list(records),
    do: Enum.map(records, &nilify_timestamps/1)

  defp nilify_timestamps(record), do: %{record | inserted_at: nil, updated_at: nil}
end
