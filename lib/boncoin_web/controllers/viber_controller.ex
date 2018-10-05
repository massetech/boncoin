defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members, Contents}
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
  def callback(conn, %{"event" => "webhook", "timestamp" => timestamp, } = params) do
    IO.puts("Webhook confirmed at #{timestamp}")
    conn
      |> put_status(:ok)
      |> render("confirm_answer.json", status: "ok")
  end

  # Welcome message when a user opens a new conversation
  def callback(conn, %{"event" => "conversation_started", "user" => %{"name" => viber_name}} = params) do
    IO.puts("#{viber_name} opened a new conversation")

    %{scope: scope, msg: msg} = %{scope: "welcome", user: conn.assigns.current_user, announce: nil, bot: %{provider: "viber", bot_user_id: nil, bot_user_name: viber_name, user_msg: nil}}
      |> BotDecisions.call_bot_algorythm()
      |> List.first()

    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: %{name: "PawChaungKaung", avatar: ""}, message: msg, tracking_data: scope)
  end

  # Treat a message comming from the user
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")

    scope = params["message"]["tracking_data"] || nil # scope is not always there (1st discussion)
    %{scope: scope, user: conn.assigns.current_user, announce: nil, bot: %{provider: "viber", bot_user_id: viber_id, bot_user_name: viber_name, user_msg: user_msg}}
      |> BotDecisions.call_bot_algorythm()
      |> IO.inspect()
      |> Enum.map(fn result_map -> ViberApi.send_message(viber_id, result_map.scope, result_map.msg) end)

    conn
      |> put_status(:ok)
      |> render("confirm_answer.json", status: "ok")
  end

  # Notification that a message was delivered to user
  def callback(conn, %{"event" => "delivered", "timestamp" => timestamp, "user_id" => user_id} = params) do
    IO.puts("Message delivered to #{user_id} at #{timestamp}")
    conn
      |> put_status(:ok)
      |> render("confirm_answer.json", status: "ok")
  end

  # The user left
  def callback(conn, %{"event" => "unsubscribed", "timestamp" => timestamp, "user_id" => user_id} = params) do
    IO.puts("The user #{user_id} left at #{timestamp}")
    conn
      |> put_status(:ok)
      |> render("confirm_answer.json", status: "ok")
  end

end
