use Mix.Config

config :boncoin, BoncoinWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/webpack/bin/webpack.js", "--mode", "development", "--watch-stdin",
  cd: Path.expand("../assets", __DIR__)]]
  # watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
  #                   cd: Path.expand("../assets", __DIR__)]]

# Configure your database
config :boncoin, Boncoin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "boncoin_dev",
  hostname: "localhost",
  pool_size: 10

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_AUTH_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_AUTH_CLIENT_SECRET2")

config :boncoin, Boncoin.Auth.Guardian,
  secret_key: System.get_env("GUARDIAN_SECRET")

config :arc,
  bucket: System.get_env("GOOGLE_CLOUD_BUCKET")
# config :goth, json: "GCP_CREDENTIALS"
config :goth, json: {:system, "GCP_CREDENTIALS"}
# config :goth,
#   json: "secrets/google_cloud_keyfile.json" |> Path.expand |> File.read!

# Watch static and templates for browser reloading.
config :boncoin, BoncoinWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/boncoin_web/views/.*(ex)$},
      ~r{lib/boncoin_web/templates/.*(eex)$},
      ~r{web/templates/.*(eex|haml)$},
      ~r{web/templates/.*(eex|drab)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
