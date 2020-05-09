defmodule Peasant.ToolsTest do
  use Peasant.GeneralCase

  alias Peasant.Tools

  alias Peasant.Tools.FakeTool

  @tools Peasant.Tool.domain()

  setup do
    Peasant.subscribe(@tools)
  end

  describe "Tools" do
    @describetag :unit

    test "should have actions/0 func" do
      assert %{} = actions = Tools.actions()

      for {action, tools} <- actions do
        assert Code.ensure_compiled(action)
        assert is_list(tools)
      end
    end

    test "should have list/0" do
      {:ok, tool_uuid} = Peasant.Tool.register(FakeTool, new_tool())

      assert_receive %Peasant.Tool.Event.Registered{}

      assert [%FakeTool{uuid: ^tool_uuid}] = Tools.list()
    end

    test "should have get/1" do
      {:ok, tool_uuid} = Peasant.Tool.register(FakeTool, new_tool())

      assert_receive %Peasant.Tool.Event.Registered{}

      assert %FakeTool{uuid: ^tool_uuid} = Tools.get(tool_uuid)
    end
  end
end
