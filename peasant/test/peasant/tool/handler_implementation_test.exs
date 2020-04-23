defmodule Peasant.Tool.HandlerImplementationTest do
  use Peasant.GeneralCase

  alias Peasant.Tool.Handler

  alias Peasant.Tools.FakeTool
  alias Peasant.Tool.Action
  alias Peasant.Tool.Event

  setup do
    Peasant.subscribe("tools")
    :ok
  end

  setup context do
    [tool: make_tool(context)]
  end

  describe "registration process" do
    @describetag :integration

    setup :register_tool

    test "should notify about tool registeration", %{tool_registered: registered} do
      assert_receive ^registered
    end
  end

  describe "commit action process" do
    @describetag :unit

    test "should fire %ActionFailed{details: %{error: :tool_must_be_attached}} event if a tool isn't attached",
         %{tool: tool} do
      action = Action.FakeAction
      action_ref = UUID.uuid4()

      action_failed_event =
        Event.ActionFailed.new(
          tool_uuid: tool.uuid,
          action_ref: action_ref,
          details: %{error: :tool_must_be_attached}
        )

      assert {:noreply, tool} == Handler.handle_cast({:commit, action, action_ref}, tool)
      assert_receive ^action_failed_event
    end

    test "should fire returned from action implementation events and put a new tool structure into the state",
         %{tool: %{config: config} = tool} do
      to_change = Faker.Lorem.word()

      action = Action.FakeAction
      action_ref = UUID.uuid4()
      config = Map.put(config, :to_change, to_change)

      tool = %{tool | config: config, attached: true}

      assert {:ok, new_tool, [event]} = Action.FakeAction.run(tool, action_ref)

      assert {:noreply, ^new_tool} = Handler.handle_cast({:commit, action, action_ref}, tool)

      assert_receive ^event
    end

    test "should fire returned from action implementation events and put a new tool structure into the state 2",
         %{tool: %{config: config} = tool} do
      error = Faker.Lorem.sentence()

      action = Action.FakeAction
      action_ref = UUID.uuid4()
      config = Map.put(config, :error, error)

      tool = %{tool | config: config, attached: true}

      assert {:ok, ^tool, [event]} = Action.FakeAction.run(tool, action_ref)

      assert {:noreply, ^tool} = Handler.handle_cast({:commit, action, action_ref}, tool)

      assert_receive ^event
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
    registered = Peasant.Tool.Event.Registered.new(tool_uuid: tool.uuid, details: %{tool: tool})
    assert {:ok, _} = Handler.register(tool)

    [tool_registered: registered]
  end

  # def commit_action(%{tool_registered: %{tool: tool}}) do

  #   attached_event = FakeTool.Attached.new(tool: %{tool | attached: true})
  #   [attached_event: attached_event]
  # end
end
