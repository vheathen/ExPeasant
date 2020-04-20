defmodule Peasant.Tool.HandlerImplementationTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Handler

  alias Peasant.Tools.FakeTool

  setup do
    tool_spec = new_tool()

    tool = FakeTool.new(tool_spec)

    [tool: tool]
  end

  describe "register/1" do
    @describetag :integration

    setup %{tool: tool} do
      Peasant.subscribe("tools")

      registered = FakeTool.Registered.new(tool)

      assert {:ok, _} = Handler.register(tool)

      [tool_registered: registered]
    end

    test "should notify about tool registeration", %{tool_registered: registered} do
      assert_receive ^registered
    end
  end
end
