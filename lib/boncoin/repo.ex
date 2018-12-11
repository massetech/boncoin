defmodule Boncoin.Repo do
  use Ecto.Repo,
    otp_app: :boncoin,
    adapter: Ecto.Adapters.Postgres

  use Paginator,
    limit: 10,                  # sets the default limit to 10
    include_total_count: true   # include total count by default
    # maximum_limit: 100,         # sets the maximum limit to 100

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end
