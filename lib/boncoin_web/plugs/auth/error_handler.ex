defmodule Boncoin.Auth.ErrorHandler do
  import Plug.Conn
  use BoncoinWeb, :controller

  def auth_error(conn, {_type, _reason}, _opts) do
    case conn.private.phoenix_format do
      "json" ->
        conn
          |> put_status(401)
          |> render(BoncoinWeb.ErrorView, "401.json")
      "html" ->
        conn
          |> put_flash(:error, "You must be logged in to access that part.")
          |> redirect(to: "/")
    end
  end

end
