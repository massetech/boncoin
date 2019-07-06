use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :boncoin, BoncoinWeb.Endpoint,
  http: [port: 4001],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  secret_salt: System.get_env("SECRET_SALT"),
  # viber_secret: System.get_env("VIBER_SECRET"),
  messenger_secret: System.get_env("MESSENGER_SECRET"),
  messenger_page_access: System.get_env("MESSENGER_PAGE_ACCESS"),
  messenger_user_id: System.get_env("MESSENGER_USER_ID"),
  google_analytics: false,
  website_url: "http://localhost:4001",
  environment: :test,
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :boncoin, Boncoin.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "boncoin_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_AUTH_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_AUTH_CLIENT_SECRET")

config :boncoin, Boncoin.Auth.Guardian,
  secret_key: System.get_env("GUARDIAN_SECRET")

config :arc,
  bucket: System.get_env("GOOGLE_CLOUD_BUCKET")

config :goth, json: "secrets/google_service.json" |> Path.expand |> File.read!
# config :goth, json: {:system, "GCP_CREDENTIALS"}

config :cipher, keyphrase: "testiekeyphraseforcipher",
  ivphrase: "testieivphraseforcipher",
  magic_token: "magictoken"
