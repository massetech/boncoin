defmodule Boncoin.Plug.LoadAdds do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    background_id = Enum.random([1, 4, 5, 6])
    conn
      |> assign(:background_id, background_id)
  end

end
