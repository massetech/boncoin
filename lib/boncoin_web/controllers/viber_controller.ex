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
  def callback(conn, %{"event" => "conversation_started", "user" => %{"name" => user_name}} = params) do
    IO.puts("#{user_name} opened a new conversation")
    %{tracking_data: tracking_data, msg: msg} = case conn.assigns.current_user do
      nil -> ViberBot.treat_msg("welcome")
      user -> ViberBot.treat_msg("welcome_back", user)
    end
    sender = build_sender()
    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: sender, message: msg, tracking_data: tracking_data)
  end

  # Receive a message from the user with tracking_data
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")
    IO.inspect(params)

    # Set up variables
    language = nil
    tracking_data = params["message"]["tracking_data"] || nil
    msg_first_key = String.slice(user_msg,0,1)
    msg_five_key = String.slice(user_msg,0,5) |> IO.inspect()
    user = conn.assigns.current_user
    {tracking_data, language} = case tracking_data do
      "language" -> {"language", convert_language(msg_first_key)}
      "link_phone_mr" -> {"link_phone", "mr"}
      "link_phone_my" -> {"link_phone", "my"}
      "link_phone_en" -> {"link_phone", "en"}
      _ ->
        if user != nil do
          case msg_five_key do
            "*123#" -> {"change_language", user.language} # User wants to change his language
            "*111#" -> {"list_offers", user.language} # User wants to see his offers
            "*888#" -> {"change_phone", user.language} # User wants to change his phone number
            "*999#" -> {"quit_viber", user.language} # User wants to quit Viber
            _ -> {tracking_data, user.language}
          end
        else
          {"language", nil}  # Fallback for language scope if any problem
        end
    end

    # Call bot algorythm and send the resulting messages to viber API
    bot_datas = %{tracking_data: tracking_data, announce: %{}, params: %{user: user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}}
      |> ViberBot.call_bot_algorythm()
      |> Enum.map(fn result_map -> send_viber_message(viber_id, result_map.tracking_data, result_map.msg) end)

    # Confirm to Viber the msg was well received
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

  defp convert_language(msg_first_key) do
    case msg_first_key do
      "1" -> "mr"
      "2" -> "my"
      "3" -> "en"
      _ -> nil
    end
  end

  # Viber msg signature
  def build_sender() do
    %{name: "PawChaungKaung", avatar: ""}
  end

end
