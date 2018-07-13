defmodule Boncoin.Plug.LoadSelects do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    conn
      |> assign(:divisions, Contents.list_divisions_active())
      |> assign(:familys, Contents.list_familys_active())
  end

end
