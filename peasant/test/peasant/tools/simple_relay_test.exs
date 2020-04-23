defmodule Peasant.Tools.SimpleRelayTest do
  use Peasant.GeneralCase

  alias Peasant.Tools.SimpleRelay

  alias Peasant.Tool.Action.{
    TurnOn,
    TurnOff
  }

  alias Peasant.Tool.Event.{
    TurnedOn,
    TurnedOff
  }

  setup do
    assert %SimpleRelay{} = relay = SimpleRelay.new(new_tool())
    config = %{pin: pin = get_even_number()}

    {:ok, check_pin} = Circuits.GPIO.open(pin + 1, :input)

    relay = %{relay | attached: true, config: config}

    on_exit(fn ->
      Circuits.GPIO.close(check_pin)
    end)

    [relay: relay, check_pin: check_pin]
  end

  describe "SimpleRelay" do
    test "should be a struct", do: :ok
  end

  describe "SimpleRelay TurnOn" do
    @describetag :unit

    setup %{check_pin: check_pin} do
      assert Circuits.GPIO.read(check_pin) == 0

      :ok
    end

    test "should actually turn GPIO up and return TurnedOn event", %{
      relay: relay,
      check_pin: check_pin
    } do
      action_ref = UUID.uuid4()
      event = TurnedOn.new(tool_uuid: relay.uuid, action_ref: action_ref)

      assert {:ok, ^relay, [^event]} = TurnOn.run(relay, action_ref)

      assert Circuits.GPIO.read(check_pin) == 1
    end
  end

  describe "SimpleRelay TurnOff" do
    @describetag :unit

    setup %{relay: %{config: %{pin: pin}}, check_pin: check_pin} do
      {:ok, ref_pin} = Circuits.GPIO.open(pin, :output)
      assert :ok = Circuits.GPIO.write(ref_pin, 1)
      Circuits.GPIO.close(ref_pin)

      assert Circuits.GPIO.read(check_pin) == 1

      [check_pin: check_pin]
    end

    test "should actually turn GPIO down and return TurnedOff event", %{
      relay: relay,
      check_pin: check_pin
    } do
      action_ref = UUID.uuid4()
      event = TurnedOff.new(tool_uuid: relay.uuid, action_ref: action_ref)

      assert {:ok, ^relay, [^event]} = TurnOff.run(relay, action_ref)

      assert Circuits.GPIO.read(check_pin) == 0
    end
  end

  defp get_even_number do
    require Integer

    case Faker.Random.Elixir.random_between(0, 28) do
      number when Integer.is_even(number) -> number
      _ -> get_even_number()
    end
  end
end
