defmodule Boncoin.Auth.SetApiToken do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    salt = Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:secret_salt]
    user = conn.assigns.current_user
    token = Phoenix.Token.sign(conn, salt, user.id)
    conn
      |> assign(:api_key, token)
  end
end
