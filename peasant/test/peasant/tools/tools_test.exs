defmodule Peasant.ToolsTest do
  use Peasant.GeneralCase

  alias Peasant.Tools

  describe "Tools" do
    @describetag :unit

    test "should have actions/0 func" do
      assert %{} = actions = Tools.actions()

      for {action, tools} <- actions do
        assert Code.ensure_compiled(action)
        assert is_list(tools)
      end
    end
  end
end
