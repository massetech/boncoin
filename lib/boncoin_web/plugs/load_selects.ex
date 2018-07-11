defmodule Boncoin.Plug.LoadSelects do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    conn
      |> assign(:divisions, Contents.list_active_divisions())
  end

end
