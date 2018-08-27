defmodule Boncoin.Auth.CurrentUser do
  import Plug.Conn
  import Guardian.Plug

  alias Boncoin.Repo
  alias Boncoin.Members.User
  alias Boncoin.Members

  def init(opts), do: opts
  def call(conn, _opts) do
    cond do
      ressource = Guardian.Plug.current_resource(conn) -> # Calls from internal controllers
        assign(conn, :current_user, Repo.get(User, ressource.id))
      true ->
        assign(conn, :current_user, Members.get_guest_user())
    end
  end
end
