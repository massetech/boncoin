defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members, Contents}
  alias Boncoin.CustomModules.ViberBot

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

    %{scope: scope, msg: msg} = %{scope: "welcome", user: conn.assigns.current_user, announce: nil, viber: %{viber_id: nil, viber_name: viber_name, user_msg: nil}}
      |> ViberBot.call_bot_algorythm()
      |> List.first()
    sender = build_sender()

    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: sender, message: msg, tracking_data: scope)
  end

  # Treat a message comming from the user
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")

    tracking_data = params["message"]["tracking_data"] || nil
    %{scope: tracking_data, user: conn.assigns.current_user, announce: nil, viber: %{viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}}
      |> ViberBot.call_bot_algorythm()
      |> Enum.map(fn result_map -> send_viber_message(viber_id, result_map.tracking_data, result_map.msg) end)

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

  # ---------------------------- FUNCTIONS -------------------------------------

  # Send datas to viber API
  def send_viber_message(viber_id, tracking_data, message) do
    data = %{
      sender: build_sender(),
      receiver: viber_id,
      type: "text",
      tracking_data: tracking_data,
      text: message
    }
    ViberApi.post("send_message", data)
  end

  # Viber msg signature
  def build_sender() do
    %{name: "PawChaungKaung", avatar: ""}
  end

end
