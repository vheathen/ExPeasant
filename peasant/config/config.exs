# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :peasant, PeasantWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "O4SRNqggemX1HjAIgllPp2N4RKLxERnJu1fk6LqmoDwp0uAfaBExJfFWUcQqRgZ2",
  render_errors: [view: PeasantWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Peasant.PubSub,
  live_view: [signing_salt: "w5BASwzz"]

config :peasant, Actions, peasant: Peasant.Tool.Action

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
