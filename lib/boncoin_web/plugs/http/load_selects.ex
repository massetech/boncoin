defmodule Boncoin.Plug.LoadSelects do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    select_menus = %{
      divisions: Contents.list_divisions_active(),
      familys: Contents.list_familys_active()
    }
    conn
      |> assign(:select_menus, select_menus)
  end

end
