defmodule Panel.Tools.GenericRelay do
  @moduledoc false

  # , no_config: true
  use Panel.Tools.Tool

  @raw_actions [
    %{
      code: "turn_on",
      name: "Turn On",
      events: ["turned_on"]
    },
    %{
      code: "turn_off",
      name: "Turn Off",
      events: ["turned_off"]
    }
  ]

  @actions Panel.Tools.Action.prepare_actions(@raw_actions)

  @impl true
  def maybe_attach(%{pin: pin}) when is_integer(pin) and pin >= 0, do: :ok
  def maybe_attach(_), do: {:error, :config_error, []}

  @impl true
  def detach(_), do: :ok

  @impl true
  def actions_list(), do: @actions

  @impl true
  def do_action(%{config: %{pin: pin}}, "turn_on", _) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    Circuits.GPIO.write(gpio, 1)
    notify(@domain, "turned_on", %{})
  end

  def do_action(%{pin: pin}, "turn_off", _) do
    {:ok, gpio} = Circuits.GPIO.open(pin, :output)
    Circuits.GPIO.write(gpio, 0)
    notify(@domain, "turned_off", %{})
  end
end
