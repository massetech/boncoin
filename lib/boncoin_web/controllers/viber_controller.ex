defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  import Mockery.Macro
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
      |> redirect(to: Routes.main_path(conn, :dashboard))
  end

  # Disconnect of Webhook
  def disconnect(conn, _params) do
    IO.puts("Disconnect from Viber Webhook")
    ViberApi.post("set_webhook", %{url: ""})
    conn
      |> redirect(to: Routes.main_path(conn, :dashboard))
  end

  # ---------------------------- CALLBACKS -------------------------------------

  # Answer to Viber to confirm the Webhook connection
  def callback(conn, %{"event" => "webhook", "timestamp" => timestamp, }) do
    IO.puts("Webhook confirmed at #{timestamp}")
    send_resp(conn, 200, "ok")
  end

  # Welcome message when a user opens a new conversation
  def callback(conn, %{"event" => "conversation_started", "user" => %{"id" => viber_id, "name" => viber_name}}) do
    IO.puts("#{viber_name} opened a new conversation on Viber at #{Timex.now()}")

    # Treat the message
    conversation = Members.get_or_initiate_conversation("viber", viber_id, viber_name)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: nil}
      |> BotDecisions.call_bot_algorythm()

    # Send response
    case Members.update_conversation(conversation, %{scope: results.scope, language: results.language}) do
      {:ok, _} ->
        conn
          |> put_status(:ok)
          |> render("send_message.json", sender: %{name: "PawChaungKaung", avatar: ""}, message: List.first(results.messages), tracking_data: results.scope)
      {:error, _changeset} ->
        send_resp(conn, 200, "ok")
        IO.puts("Viber error : can't initiate conversation with user")
    end
  end


  # Treat a message comming from the user
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")

    # Treat the message
    conversation = Members.get_or_initiate_conversation("viber", viber_id, viber_name)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: user_msg}
      |> BotDecisions.call_bot_algorythm()

    # Send response
    if results.scope == "close" do
      case Members.delete_conversation(conversation) do
        {:ok, _} -> Enum.map(results.messages, fn message -> mockable(ViberApi).send_message(viber_id, message) end)
        {:error, _changeset} -> IO.puts("Messenger error : can't delete conversation #{conversation.id}")
      end
    else
      case Members.update_conversation(conversation, %{scope: results.scope, language: results.language}) do
        {:ok, _} -> Enum.map(results.messages, fn message -> mockable(ViberApi).send_message(viber_id, message) end)
        {:error, _changeset} -> IO.puts("Messenger error : can't update conversation #{conversation.id}")
      end
    end

    # case Members.update_conversation(conversation, %{scope: results.scope, language: results.language}) do
    #   {:ok, _} -> Enum.map(results.messages, fn message -> ViberApi.send_message(viber_id, message) end)
    #   {:error, _changeset} -> IO.puts("Viber error : can't update conversation")
    # end

    send_resp(conn, 200, "ok")
  end

  # Notification that a message was delivered to user
  def callback(conn, %{"event" => "delivered", "timestamp" => timestamp, "user_id" => user_id}) do
    IO.puts("Message delivered to #{user_id} at #{timestamp}")
    send_resp(conn, 200, "ok")
  end

  # The user left
  def callback(conn, %{"event" => "unsubscribed", "timestamp" => timestamp, "user_id" => user_id}) do
    IO.puts("The user #{user_id} left at #{timestamp}")
    send_resp(conn, 200, "ok")
  end

end
