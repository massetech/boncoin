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
    auth_messenger = get_req_header(conn, "user-agent")
      |> List.first()

    # API call from internal
    cond do
      auth_internal != nil ->
        case Phoenix.Token.verify(conn, salt, auth_internal, max_age: 60*60*12) do
          {:ok, user_id} -> # API call authorized
            user  = Members.get_user!(user_id)
            case user.active do
              true -> assign(conn, :current_user, user) # Only active user can be current user
              false -> assign(conn, :current_user, Members.get_guest_user())
            end
            # conn
            #   |> assign(:current_user, Members.get_user!(user_id))
          {:error, _} -> # API call refused token too old (12h)
            message = "Token too old. Reload the page."
            conn
              |> put_status(401)
              |> Phoenix.Controller.render(BoncoinWeb.ErrorView, "401.json", message: message)
              |> halt()
        end

      # API call from Viber
      auth_viber != nil ->
        viber_id = conn.params["sender"]["id"] || conn.params["user_id"] || nil
        user = Members.get_active_user_by_bot_id(viber_id, "viber")
        conn
          |> assign(:current_user, user)

      # API call from Facebook
      auth_messenger != nil && auth_messenger =~ "facebook" ->
        messenger_id = params_from_messenger(conn.params) || nil
        user = Members.get_active_user_by_bot_id(messenger_id, "messenger")
        conn
          |> assign(:current_user, user)

      # Other call = Danger !
      true ->
        conn
          |> put_status(401)
          # |> send_resp(conn, 403, "Unauthorized")
          |> halt()
    end
  end

  defp params_from_messenger(params) do
    case Map.has_key?(params, "entry") do
      false -> nil
      true ->
        params["entry"]
          |> List.first()
          |> Map.get("messaging")
          |> List.first()
          |> Map.get("sender")
          |> Map.get("id")
    end
  end
end
