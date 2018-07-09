# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :boncoin,
  ecto_repos: [Boncoin.Repo],
  api_url: System.get_env("API_URL")

config :boncoin, Boncoin.Gettext,
  default_locale: "en",
  locales: ~w(en bi)

# config :everlearn, Everlearn.Auth.Guardian,
#   issuer: "Everlearn.#{Mix.env}",
#   ttl: {30, :days},
#   verify_issuer: true

# config :ueberauth, Ueberauth,
#   providers: [
#     google: {Ueberauth.Strategy.Google, [default_scope: "profile email https://www.googleapis.com/auth/plus.login"]}
#   ]

# Configures the endpoint
config :boncoin, BoncoinWeb.Endpoint,
  url: [host: "localhost"],
  # secret_key_base: "DsxGTu0oUzBYL0WesR04jz8x/BndI2Aqqrs+bsgPIO7vBuMcoX6e8gV50iEQa3L5",
  render_errors: [view: BoncoinWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Boncoin.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
