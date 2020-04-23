defimpl Peasant.Tool.Action.FakeAction, for: Peasant.Tools.FakeTool do
  alias Peasant.Tool.Event

  def run(%{config: %{error: error}} = tool, action_ref) do
    event =
      Event.FakeFailure.new(
        tool_uuid: tool.uuid,
        action_ref: action_ref,
        details: %{error: error}
      )

    {:ok, tool, [event]}
  end

  def run(%{config: config} = tool, action_ref) do
    event = Event.FakeSuccess.new(tool_uuid: tool.uuid, action_ref: action_ref)
    config = Map.put(config, :changes, config.to_change)
    tool = %{tool | config: config}

    {:ok, tool, [event]}
  end

  def resulting_events(_tool), do: [Event.FakeSuccess, Event.FakeFailure]

  def template(_tool), do: %{}
end
