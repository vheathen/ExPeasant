# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

#
config :panel, Panel.Tools,
  types: [
    Panel.Tools.Sleeper,
    Panel.Tools.GenericRelay
  ]

# Configures the endpoint
config :panel, PanelWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Lrk7/M41YlkWI31+pSjN8ZCerhMmN7Zn5M9+af+693aWiwzmzFM8PD9HR4xaXTBz",
  render_errors: [view: PanelWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Nerves.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "ngJKieFf"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
