defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members}
  alias Boncoin.CustomModules.BotDecisions

# ---------------------------- CONNECTION -------------------------------------

  # Connect to Webhook
  def connect(conn, _params) do
    IO.puts("Connect to Viber Webhook sent")
    params = %{
      url: System.get_env("VIBER_API_URL"),
      event_types: ["delivered", "failed", "subscribed", "unsubscribed", "conversation_started"],
      send_name: true,
      send_photo: false
    }
    ViberApi.post("set_webhook", params)
    conn
      |> redirect(to: main_path(conn, :dashboard))
  end

  # Disconnect of Webhook
  def disconnect(conn, _params) do
    IO.puts("Disconnect from Viber Webhook")
    ViberApi.post("set_webhook", %{url: ""})
    conn
      |> redirect(to: main_path(conn, :dashboard))
  end

  # ---------------------------- CALLBACKS -------------------------------------

  # Answer to Viber to confirm the Webhook connection
  def callback(conn, %{"event" => "webhook", "timestamp" => timestamp, }) do
    IO.puts("Webhook confirmed at #{timestamp}")
    send_resp(conn, 200, "ok")
    # conn
    #   |> put_status(:ok)
    #   |> render("confirm_answer.json", status: "ok")
  end

  # Welcome message when a user opens a new conversation
  def callback(conn, %{"event" => "conversation_started", "user" => %{"name" => viber_name}}) do
    IO.puts("#{viber_name} opened a new conversation at #{Timex.now()}")

    results = %{scope: "welcome", user: conn.assigns.current_user, announce: nil, bot: %{bot_provider: "viber", bot_id: nil, bot_user_name: viber_name, user_msg: nil}}
      |> BotDecisions.call_bot_algorythm()

    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: %{name: "PawChaungKaung", avatar: ""}, message: List.first(results.messages), tracking_data: results.scope)
  end

  # Treat a message comming from the user
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")
    actual_conv = Members.get_actual_conversation_by_provider_psid("viber", viber_id)
    scope = params["message"]["tracking_data"] || actual_conv.scope
    results = %{scope: scope, user: conn.assigns.current_user, announce: nil, bot: %{bot_provider: "viber", bot_id: viber_id, bot_user_name: viber_name, user_msg: user_msg}}
      |> BotDecisions.call_bot_algorythm()
    #   |> Enum.map(fn result_map -> ViberApi.send_message(viber_id, result_map.scope, result_map.msg) end)

      # Send message to the visitor
      conv_params = %{bot_provider: "viber", psid: viber_id, scope: results.scope, nickname: viber_name}
      case Members.create_or_update_conversation(conv_params) do
        {:ok, _} -> Enum.map(results.messages, fn message -> ViberApi.send_message(viber_id, message) end)
        {:error, _changeset} -> IO.puts("Viber error : can't update conversation")
      end

    send_resp(conn, 200, "ok")
    # conn
    #   |> put_status(:ok)
    #   |> render("confirm_answer.json", status: "ok")
  end

  # Notification that a message was delivered to user
  def callback(conn, %{"event" => "delivered", "timestamp" => timestamp, "user_id" => user_id}) do
    IO.puts("Message delivered to #{user_id} at #{timestamp}")
    send_resp(conn, 200, "ok")
    # conn
    #   |> put_status(:ok)
    #   |> render("confirm_answer.json", status: "ok")
  end

  # The user left
  def callback(conn, %{"event" => "unsubscribed", "timestamp" => timestamp, "user_id" => user_id}) do
    IO.puts("The user #{user_id} left at #{timestamp}")
    send_resp(conn, 200, "ok")
    # conn
    #   |> put_status(:ok)
    #   |> render("confirm_answer.json", status: "ok")
  end

end
