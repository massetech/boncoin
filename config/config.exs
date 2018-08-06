use Mix.Config

config :boncoin,
  ecto_repos: [Boncoin.Repo]

config :boncoin, Boncoin.Gettext,
  default_locale: "en",
  locales: ~w(en my mr)

config :boncoin, Boncoin.Auth.Guardian,
  issuer: "Boncoin.#{Mix.env}",
  ttl: {30, :days},
  verify_issuer: true

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "profile email https://www.googleapis.com/auth/plus.login"]}
  ]

# Configure the Haml engine
config :phoenix, :template_engines,
  haml: PhoenixHaml.Engine,
  drab: Drab.Live.Engine

# Configure Drab
config :drab, BoncoinWeb.Endpoint,
  otp_app: :boncoin,
  js_socket_constructor: "window.__socket" # Fix for Webpack

# Configure ARC image uploader to Google cloud
config :arc,
  storage: Arc.Storage.GCS

# Configures the endpoint
config :boncoin, BoncoinWeb.Endpoint,
  render_errors: [view: BoncoinWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Boncoin.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
