defmodule Boncoin.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  alias Boncoin.Members
  alias Boncoin.Router.Helpers, as: Routes

  def init(_params) do
  end

  def call(conn, _params) do
    case Members.admin_user?(conn.assigns[:current_user]) do
      true ->
        conn
      false ->
        conn
        |> put_flash(:error, "You cant access to this part.")
        |> redirect(to: "/")
    end
  end
end
