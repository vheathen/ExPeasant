defmodule Peasant.Tool.Action.AttachTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Action.Attach
  alias Peasant.Tool.Event.Attached

  alias Peasant.Tools.FakeTool

  describe "Action.Attach" do
    @describetag :unit

    test "should be implemented for any struct (but ones having :attached field)" do
      tool = new_tool() |> FakeTool.new()
      action_ref = UUID.uuid4()
      event = Attached.new(tool_uuid: tool.uuid, action_ref: action_ref)

      attached_tool = %{tool | attached: true}

      assert {:ok, attached_tool, [event]} == Attach.run(tool, action_ref)
    end
  end
end
