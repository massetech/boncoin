defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  import Mockery.Macro
  alias Boncoin.{Members, ViberApi}
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

  # ---------------------------- RECEIVE MESSAGE -------------------------------------

  # conversation_started : welcome message when a user opens a new conversation
  def callback(conn, %{"event" => "conversation_started", "context" => context, "user" => %{"id" => viber_id, "name" => viber_name}}) do
    IO.puts("#{viber_name} opened a new conversation on Viber at #{Timex.now()}")
    case treat_message(conn, viber_id, viber_name, nil, context) do
      {:new, msg} ->
        conn
          |> put_status(:ok)
          |> render("send_message.json", sender: %{name: "PawChaungKaung", avatar: ""}, message: msg, tracking_data: nil)
      :ok ->
        send_resp(conn, 200, "ok")
      :error ->
        IO.puts("Viber error : can't initiate conversation conversation_started")
        send_resp(conn, 200, "ok")
    end
  end

  # Treat a message comming from the user
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    # IO.inspect(params)
    cond do
      user_msg =~ "http" -> # Links on Viber rich_media are reposted : stop any message like that from being treated
        IO.puts("http auto message stopped")
        send_resp(conn, 200, "ok")
      true -> # It is not a link response
        IO.puts("User #{viber_id} spoke at #{timestamp}")
        case treat_message(conn, viber_id, viber_name, user_msg, nil) do
          :ok ->
            send_resp(conn, 200, "ok")
          :error ->
            IO.puts("Viber error : can't update conversation message")
            send_resp(conn, 200, "ok")
        end
    end
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

  # ---------------------------- ANSWER TO MESSAGE -------------------------------------

  defp treat_message(conn, viber_id, viber_name, user_msg, origin) do
    conversation = Members.get_or_initiate_conversation("viber", viber_id, viber_name, nil)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: user_msg}
      |> BotDecisions.call_bot_algorythm()

    case Members.update_conversation(conversation, results.conversation) do
      {:ok, _} ->
        cond do
          user_msg == nil && conn.assigns.current_user == nil -> # Callback to an unknown user opening a new conversation
            {:new, results.messages.message}
          true -> # Answer to user new msg
            mockable(ViberApi).send_message(nil, conversation.psid, results.messages.message, results.messages.quick_replies, results.messages.buttons, nil)
            Enum.map(results.messages.offers, fn map -> mockable(ViberApi).send_message(nil, conversation.psid, map.message, [], map.buttons, map.offer) end)
            :ok
        end
      {:error, changeset} ->
        IO.inspect(changeset)
        :error
    end
  end
end
