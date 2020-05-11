defmodule Firmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  @target Mix.Project.config()[:target]

  use Application

  require Logger

  def start(_type, _args) do
    Logger.info(inspect(VintageNet.configured_interfaces()))

    VintageNet.configured_interfaces()
    |> Enum.any?(&(&1 =~ ~r/^wlan/))
    |> maybe_start_wifi_wizard()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Firmware.Supervisor]
    Supervisor.start_link(children(@target), opts)
  end

  # List all child processes to be supervised
  def children("host") do
    [
      # Starts a worker by calling: Firmware.Worker.start_link(arg)
      # {Firmware.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Starts a worker by calling: Firmware.Worker.start_link(arg)
      # {Firmware.Worker, arg},
    ]
  end

  @doc false
  def on_wizard_exit() do
    # This function is used as a callback when the WiFi Wizard
    # exits which is useful if you need to do work after
    # configuration is done, like restart web servers that might
    # share a port with the wizard, etc etc
    Logger.info("[PeasantWiFi] - WiFi Wizard stopped")
  end

  defp maybe_start_wifi_wizard(_wifi_configured? = true) do
    # By this point we know there is a wlan interface available
    # and already configured. This would normally mean that you
    # should then skip starting the WiFi wizard here so that
    # the device doesn't start the WiFi wizard after every
    # reboot.
    #
    # However, for the example we want to always run the
    # WiFi wizard on startup. Comment/remove the function below
    # if you want a more typical experience skipping the wizard
    # after it has been configured once.
    Logger.info("[PeasantWiFi] - WiFi Wizard didn't start")
    # VintageNetWizard.run_wizard(on_exit: {__MODULE__, :on_wizard_exit, []})
  end

  defp maybe_start_wifi_wizard(_wifi_not_configured) do
    VintageNetWizard.run_wizard(on_exit: {__MODULE__, :on_wizard_exit, []})
  end
end
