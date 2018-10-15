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
        user = Repo.get(User, ressource.id)
        case user.active do
          true -> assign(conn, :current_user, user) # Only active user can be current user
          false -> assign(conn, :current_user, Members.get_guest_user())
        end
      true -> assign(conn, :current_user, Members.get_guest_user())
    end
  end
end
