use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :panel, PanelWeb.Endpoint,
  http: [port: 4002],
  server: false

config :panel, :paneldb, "data/paneldb_test"

# Print only warnings and errors during test
config :logger, level: :warn
