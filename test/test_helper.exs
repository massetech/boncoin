ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Boncoin.Repo, :manual)

# test/support/helpers.ex
# defmodule Boncoin.Support.Helpers do
#   def launch_api do
#     # set up config for serving
#     endpoint_config =
#       Application.get_env(:boncoin, Boncoin.Endpoint)
#       |> Keyword.put(:server, true)
#     :ok = Application.put_env(:boncoin, Boncoin.Endpoint, endpoint_config)
#
#     # restart our application with serving enabled
#     :ok = Application.stop(:boncoin)
#     :ok = Application.start(:boncoin)
#   end
# end
