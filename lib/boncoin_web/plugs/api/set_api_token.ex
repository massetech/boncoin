defmodule Boncoin.Auth.SetApiToken do
  import Plug.Conn

  @salt System.get_env("SECRET_SALT")

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns.current_user
    token = Phoenix.Token.sign(conn, @salt, user.id)
    conn
      |> assign(:api_key, token)
  end
end
