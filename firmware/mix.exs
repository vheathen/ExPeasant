defmodule Firmware.MixProject do
  use Mix.Project

  @app :peasant_nerves
  @name "PeasantGrowController"
  @version "0.2.2"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :x86_64]

  def project do
    [
      app: @app,
      name: @name,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Firmware.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.6.1", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},
      {:peasant, path: "../peasant"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.8", targets: @all_targets},
      {:nerves_pack, "~> 0.2", targets: @all_targets},

      # nerves hub
      {:nerves_hub_cli, "~> 0.1", runtime: false},
      {:nerves_hub_link, "~> 0.1", targets: @all_targets},
      {:nerves_time, "~> 0.2"},

      # VintageNet Wizard
      {:vintage_net_wizard, "~> 0.2", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi, "~> 1.11", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.11", runtime: false, targets: :rpi0},
      {:nerves_system_rpi2, "~> 1.11", runtime: false, targets: :rpi2},
      {:nerves_system_rpi3, "~> 1.11", runtime: false, targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.11", runtime: false, targets: :rpi3a},
      {:nerves_system_rpi4, "~> 1.11", runtime: false, targets: :rpi4},
      {:nerves_system_bbb, "~> 2.6", runtime: false, targets: :bbb},
      {:nerves_system_x86_64, "~> 1.11", runtime: false, targets: :x86_64}
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
