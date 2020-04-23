defimpl Peasant.Tool.Action.TurnOff, for: Peasant.Tools.SimpleRelay do
  alias Peasant.Tool.Event.TurnedOff

  def run(relay, action_ref) do
    turned_on = TurnedOff.new(tool_uuid: relay.uuid, action_ref: action_ref)

    turn_off(relay)

    {:ok, relay, [turned_on]}
  end

  def resulting_events(_tool), do: [TurnedOff]

  def template(_tool), do: %{}

  defp turn_off(%{config: %{pin: pin}}) do
    {:ok, pin_ref} = Circuits.GPIO.open(pin, :output)
    Circuits.GPIO.write(pin_ref, 0)
  end
end
