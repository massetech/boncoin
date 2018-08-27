defmodule Boncoin.Repo do
  use Ecto.Repo, otp_app: :boncoin
  use Paginator
    # limit: 5,                  # sets the default limit to 10
    # maximum_limit: 100,         # sets the maximum limit to 100
    # include_total_count: true   # include total count by default
end
