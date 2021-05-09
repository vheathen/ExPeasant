defimpl Peasant.Tool.Action.TurnOn, for: Peasant.Tools.DummyTool do
  alias Peasant.Tool.Event.TurnedOn

  require Logger

  def run(dummy_tool, action_ref) do
    turned_on = TurnedOn.new(tool_uuid: dummy_tool.uuid, action_ref: action_ref)
    turn_on(dummy_tool)

    {:ok, dummy_tool, [turned_on]}
  end

  def resulting_events(_tool), do: [TurnedOn]

  def template(_tool), do: %{}

  def persist_after?(_tool), do: false

  defp turn_on(%{uuid: uuid, config: config}) do
    [
      config[:label],
      uuid,
      "Dummy tool turned ON"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(". ")
    |> Logger.info()
  end
end
