defimpl Peasant.Tool.Action.TurnOn, for: Peasant.Tools.SimpleRelay do
  alias Peasant.Tool.Event.TurnedOn

  def run(relay, action_ref) do
    turned_on = TurnedOn.new(tool_uuid: relay.uuid, action_ref: action_ref)
    turn_on(relay)

    {:ok, relay, [turned_on]}
  end

  def resulting_events(_tool), do: [TurnedOn]

  def template(_tool), do: %{}

  def persist_after?(_tool), do: false

  defp turn_on(%{config: %{pin: pin}}) do
    {:ok, pin_ref} = Circuits.GPIO.open(pin, :output)
    Circuits.GPIO.write(pin_ref, 1)
  end
end
