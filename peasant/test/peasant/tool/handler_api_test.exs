defmodule Peasant.Tool.HandlerAPITest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Handler

  alias Peasant.Tools.FakeTool

  setup do
    uuid = UUID.uuid4()

    spec = %{uuid: uuid, test_pid: self()}

    start_supervised(FakeHandler, handler_child_spec(FakeHandler, spec))

    [uuid: uuid]
  end

  describe "start_link/1" do
    @describetag :unit

    setup :fake_tool

    test "should start a process with via_tuple name", %{fake_tool: %{uuid: uuid} = tool} do
      assert {:ok, pid} = Handler.start_link(tool)
      assert is_pid(pid)
      assert [{pid, nil}] = Registry.lookup(Peasant.Registry, uuid)
    end
  end

  describe "register/1" do
    @describetag :integration

    setup :fake_tool

    setup %{fake_tool: tool} do
      assert {:ok, pid} = Handler.register(tool)
      [tool: tool, pid: pid]
    end

    test "should start a handler process via Toolbox supervisor", %{pid: pid} do
      assert {:undefined, pid, :worker, [Handler]} in DynamicSupervisor.which_children(
               Peasant.Toolbox
             )
    end
  end

  describe "commit/3" do
    @describetag :unit

    test "should cast {:commit, action, config} to a process with uuid as id", %{uuid: uuid} do
      config = %{some: "value"}
      assert :ok == Handler.commit(uuid, Peasant.Tool.Action.Attach, config)
      assert_receive {:cast, {:commit, Peasant.Tool.Action.Attach, ^config}}
    end

    test "should return {:error, :no_tool_exists} for a unknown uuid" do
      config = %{some: "value"}

      assert {:error, :no_tool_exists} ==
               Handler.commit(
                 UUID.uuid4(),
                 Peasant.Tool.Action.Attach.Peasant.Tools.FakeTool,
                 config
               )

      refute_receive {:cast,
                      {:commit, Peasant.Tool.Action.Attach.Peasant.Tools.FakeTool, ^config}}
    end
  end

  def fake_tool(_context) do
    tool = new_tool() |> FakeTool.new()

    [fake_tool: tool]
  end
end
