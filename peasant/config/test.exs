use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :peasant, PeasantWeb.Endpoint,
  http: [port: 4002],
  server: false

config :peasant, :peasantdb, "data/peasantdb_test"

# Print only warnings and errors during test
config :logger, level: :warn
