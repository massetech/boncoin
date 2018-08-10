defmodule Boncoin.Plug.ApiToken do
  import Plug.Conn
  # import PhoenixGon.Controller

  def init(opts), do: opts
  def call(conn, _opts) do
    # token = Phoenix.Token.sign(conn, "phone_api", "whatever")
    token = Guardian.Plug.current_token(conn)
    conn
      |> assign(:api_key, token)
  end
end
