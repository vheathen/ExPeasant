defmodule Peasant.Tool.HandlerImplementationTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Handler

  alias Peasant.Tools.FakeTool

  setup do
    Peasant.subscribe("tools")
    :ok
  end

  setup context do
    [tool: make_tool(context)]
  end

  describe "registeration process" do
    @describetag :integration

    setup :register_tool

    test "should notify about tool registeration", %{tool_registered: registered} do
      assert_receive ^registered
    end
  end

  describe "attachment process" do
    @describetag :integration

    setup [:register_tool, :attach_tool]

    test "should do nothing if tool has been already attached",
         %{
           tool_registered: %{tool: tool},
           attached_event: %{tool: attached_tool} = attached_event
         } do
      assert {:noreply, attached_tool} == Handler.handle_cast(:attach, attached_tool)

      refute_receive {:do_attach, ^tool}
      refute_receive ^attached_event
    end

    test "should call do_attach/1 callback, change :attached to true and broadcast event if tool has not been attached before",
         %{
           tool_registered: %{tool: tool},
           attached_event: %{tool: attached_tool} = attached_event
         } do
      assert {:noreply, attached_tool} == Handler.handle_cast(:attach, tool)

      assert_receive {:do_attach, ^tool}
      assert_receive ^attached_event
    end

    @tag tool_error: Faker.Lorem.word()
    test "should call do_attach/1 callback and if it returns error change nothing, but send AttachmentFailed event",
         %{
           tool_registered: %{tool: tool},
           tool_error: error
         } do
      attachment_failed_event = FakeTool.AttachmentFailed.new(tool_uuid: tool.uuid, reason: error)

      assert {:noreply, tool} == Handler.handle_cast(:attach, tool)

      assert_receive {:do_attach, ^tool}
      assert_receive ^attachment_failed_event
    end
  end

  def make_tool(%{tool_error: error}) do
    %{config: %{pid: self(), error: error}}
    |> new_tool()
    |> FakeTool.new()
  end

  def make_tool(_) do
    %{config: %{pid: self()}}
    |> new_tool()
    |> FakeTool.new()
  end

  def register_tool(%{tool: tool}) do
    registered = FakeTool.Registered.new(%{tool: tool})

    assert {:ok, _} = Handler.register(tool)

    [tool_registered: registered]
  end

  def attach_tool(%{tool_registered: %{tool: tool}}) do
    attached_event = FakeTool.Attached.new(tool: %{tool | attached: true})
    [attached_event: attached_event]
  end
end
