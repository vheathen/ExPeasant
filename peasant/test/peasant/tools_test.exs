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

    setup do
      :sys.get_state(Peasant.Collection.Observer)

      {:ok, tool_uuid} = Peasant.Tool.register(FakeTool, new_tool())
      assert_receive %Peasant.Tool.Event.Registered{}

      [tool_uuid: tool_uuid, tool_type: FakeTool]
    end

    test "should have actions/0 func" do
      assert %{} = actions = Tools.actions()

      assert length(Map.keys(actions)) > 0

      for {action, tool_types} <- actions do
        assert Code.ensure_compiled(action)
        assert is_list(tool_types)
        for type <- tool_types, do: assert(Code.ensure_compiled(type))
      end
    end

    test "should have tool_types/0 func" do
      assert %{} = tool_types = Tools.tool_types()

      assert length(Map.keys(tool_types)) > 0

      for {tool_type, actions} <- tool_types do
        assert Code.ensure_compiled(tool_type)
        assert is_list(actions)
        for action <- actions, do: assert(Code.ensure_compiled(action))
      end
    end

    test "should have get_actions_by_tool_type/1 func" do
      for {tool_type, actions} <- Tools.tool_types() do
        assert actions == Tools.get_actions_by_tool_type(tool_type)
      end
    end

    test "should have get_actions_by_tool/1 func", %{tool_uuid: tool_uuid, tool_type: tool_type} do
      assert Tools.get_actions_by_tool_type(tool_type) == Tools.get_actions_by_tool(tool_uuid)
    end

    test "should have list/0", %{tool_uuid: tool_uuid} do
      assert [%FakeTool{uuid: ^tool_uuid}] = Tools.list()
    end

    test "should have get/1", %{tool_uuid: tool_uuid} do
      assert %FakeTool{uuid: ^tool_uuid} = Tools.get(tool_uuid)
    end
  end
end
