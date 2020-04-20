defmodule Peasant.ToolTest do
  use Peasant.GeneralCase

  alias Peasant.Tools.FakeTool

  setup do
    tool_spec = new_tool()

    assert %FakeTool{} = tool = FakeTool.new(tool_spec)

    [tool_spec: tool_spec, tool: tool]
  end

  describe "Tool module" do
    @describetag :unit

    test "should intoduce State struct and functions", do: :ok
  end

  describe "register/1" do
    @describetag :unit

    test "should exist" do
      assert {:register, 1} in FakeTool.__info__(:functions)
    end

    test "should return {:ok, uuid} in case of correct tool specs", %{tool_spec: tool_spec} do
      assert {:ok, uuid} = FakeTool.register(tool_spec)
      assert is_binary(uuid)
      assert {:ok, _} = UUID.info(uuid)
    end

    test "should return {:error, error} in case of incorrect tool specs" do
      tool = new_tool() |> Map.delete(:name)
      assert {:error, _} = FakeTool.register(tool)
    end
  end

  describe "attach(tool_uuid)" do
  end
end
