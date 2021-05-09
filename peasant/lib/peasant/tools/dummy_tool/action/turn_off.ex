defimpl Peasant.Tool.Action.TurnOff, for: Peasant.Tools.DummyTool do
  alias Peasant.Tool.Event.TurnedOff

  require Logger

  def run(dummy_tool, action_ref) do
    turned_on = TurnedOff.new(tool_uuid: dummy_tool.uuid, action_ref: action_ref)

    turn_off(dummy_tool)

    {:ok, dummy_tool, [turned_on]}
  end

  def resulting_events(_tool), do: [TurnedOff]

  def template(_tool), do: %{}

  def persist_after?(_tool), do: false

  defp turn_off(%{uuid: uuid, config: config}) do
    [
      config[:label],
      uuid,
      "Dummy tool turned OFF"
    ]
    |> Enum.filter(& &1)
    |> Enum.join(". ")
    |> Logger.info()
  end
end
