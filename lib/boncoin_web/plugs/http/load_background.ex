defmodule Boncoin.Plug.LoadBackground do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    background_id = Enum.random([1, 4, 5, 6])
    conn
      |> assign(:background_url, "backgrounds/background_#{background_id}.jpg")
  end

end
