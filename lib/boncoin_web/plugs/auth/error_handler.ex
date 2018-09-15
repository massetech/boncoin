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
          |> put_flash(:alert, "You must be logged in to access that part.")
          |> put_status(308)
          |> redirect(to: "/")
          |> halt()
    end
  end

end
