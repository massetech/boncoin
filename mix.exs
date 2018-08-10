defmodule Boncoin.Mixfile do
  use Mix.Project

  def project do
    [ app: :boncoin,
      version: "1.1.0",
      elixir: "~> 1.6.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  # :exjsx, :parse_trans
  def application do
    [
      mod: {Boncoin.Application, []},
      extra_applications: [:logger, :runtime_tools, :timex, :httpotion]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.3"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:ueberauth_google, "~> 0.7"},
      {:guardian, "~> 1.0-beta"},
      {:timex, "~> 3.1"},
      {:poison, "~> 3.1"},
      {:cors_plug, "~> 1.5", only: :dev},
      {:phoenix_haml, "~> 0.2"},
      {:drab, "~> 0.9.0"},
      {:arc, "~> 0.10.0"},
      {:arc_ecto, git: "https://github.com/massetech/arc_ecto.git"},
      {:arc_gcs, "~> 0.0.8"},
      {:rabbitElixir, "~> 1.0.0"},
      {:httpotion, "~> 3.1.0"},
      {:distillery, "~> 2.0.0-rc.4"},
      {:phoenix_gon, "~> 0.4.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
