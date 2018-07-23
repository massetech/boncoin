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
  locales: ~w(en my zg)

config :boncoin, Boncoin.Auth.Guardian,
  secret_key: System.get_env("GUARDIAN_SECRET"),
  issuer: "Boncoin.#{Mix.env}",
  ttl: {30, :days},
  verify_issuer: true

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "profile email https://www.googleapis.com/auth/plus.login"]}
  ]
config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

# Configure the Haml engine
config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine,
  drab: Drab.Live.Engine

# Configure Drab
config :drab, BoncoinWeb.Endpoint,
  otp_app: :boncoin

# Configure ARC image uploader to Google cloud
config :arc,
  storage: Arc.Storage.GCS,
  bucket: "pawchaungkaung_dev"
  # bucket: System.get_env("GOOGLE_CLOUD_BUCKET")

config :goth,
  json: "secrets/google_cloud_keyfile.json" |> Path.expand |> File.read!

# Configures the endpoint
config :boncoin, BoncoinWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: BoncoinWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Boncoin.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
