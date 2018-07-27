defmodule Boncoin.Plug.CheckInput do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, opts) do
    opts |> IO.inspect()
    conn |> IO.inspect()
  end



end
