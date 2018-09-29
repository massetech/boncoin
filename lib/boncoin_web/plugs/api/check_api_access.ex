defmodule Boncoin.Auth.CheckApiAccess do
  import Plug.Conn
  alias Boncoin.Members

  def init(opts), do: opts

  def call(conn, _opts) do
    salt = Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:secret_salt]
    auth_internal = get_req_header(conn, "authorization")
      |> List.first()
    auth_viber = get_req_header(conn, "x-viber-content-signature")
      |> List.first()

    cond do
      auth_internal != nil -> # API call from internal
        case Phoenix.Token.verify(conn, @salt, auth_internal, max_age: 60*60*12) do
          {:ok, user_id} -> # API call authorized
            conn
              |> assign(:current_user, Members.get_user!(user_id))
          {:error, _} -> # API call refused token too old (12h)
            message = "Token too old. Reload the page."
            conn
              |> put_status(:unauthorized)
              |> Phoenix.Controller.render(BoncoinWeb.ErrorView, "401.json", message: message)
              |> halt()
        end
      auth_viber != nil -> # API call from Viber
        viber_id = conn.params["sender"]["id"] || conn.params["user_id"] || nil
        user = if viber_id == nil, do: nil, else: Members.get_user_by_viber_id(viber_id)
        conn
          |> assign(:current_user, user)
      true -> # Other call = Danger !
        conn
        |> put_status(401)
        |> halt()
    end
  end
end
