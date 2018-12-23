defmodule BoncoinWeb.MessengerController do
  use BoncoinWeb, :controller
  import Mockery.Macro
  alias Boncoin.{Members, MessengerApi}
  alias Boncoin.CustomModules.BotDecisions

  # ---------------------------- CONNECTION -------------------------------------

  # Answer to Messenger to confirm the Webhook connection
  def callback(conn, %{"hub.mode" => mode, "hub.verify_token" => token, "hub.challenge" => challenge} = params) do
    verify_token = System.get_env("MESSENGER_SECRET")
    if (mode == "subscribe" and token == verify_token) do
      IO.puts("Messenger webhook confirmed at #{Timex.now()}")
      send_resp(conn, 200, challenge)
    else
      IO.puts("Messenger webhook problem found at #{Timex.now()}")
      send_resp(conn, 403, "Unauthorized")
    end
  end

  # ---------------------------- RECEIVE MESSAGE -------------------------------------

  # EVENT messaging_referrals (user opens a new conversation from link m.me)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"referral" => %{"ref" => ref, "source" => source, "type" => type}, "sender" => %{"id" => messenger_id}}]}], "object" => "page"} = msg_query) do
    IO.puts("Messenger user  #{messenger_id} opened a new conversation at #{Timex.now()}")
    # IO.puts("messaging_referrals")
    # IO.inspect(msg_query)
    if treat_message(conn, messenger_id, nil, ref) == :error, do: IO.puts("Messenger error : can't open conversation messaging_referrals")
    send_resp(conn, 200, "ok")
  end

  # %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD"}, "sender" => %{"id" => messenger_id}}]}], "object" => "page"}
  # %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD"}, "sender" => %{"id" => "messenger_1234"}}]}], "object" => "page"}

  # EVENT messaging_postbacks (user opens a new conversation from messenger)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => payload, "title" => title}, "sender" => %{"id" => messenger_id}}]}], "object" => "page"} = msg_query) do
    IO.puts("Messenger user  #{messenger_id} opened a new conversation at #{Timex.now()}")
    # IO.puts("messaging_postbacks")
    # IO.inspect(msg_query)
    if treat_message(conn, messenger_id, payload, nil) == :error, do: IO.puts("Messenger error : can't open conversation messaging_postbacks")
    send_resp(conn, 200, "ok")
  end

  # EVENT message (user sends a quickreply)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"quick_reply" => %{"payload" => user_msg}}}]}], "object" => "page"} = msg_query) do
    IO.puts("Messenger user #{messenger_id} spoke at #{Timex.now()}")
    # IO.puts("quick_reply")
    # IO.inspect(msg_query)
    if treat_message(conn, messenger_id, user_msg, nil) == :error, do: IO.puts("Messenger error : can't treat message")
    send_resp(conn, 200, "ok")
  end

  # EVENT message (user types a message)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}], "object" => "page"} = msg_query) do
    IO.puts("Messenger user #{messenger_id} spoke at #{Timex.now()}")
    # IO.puts("message")
    # IO.inspect(msg_query)
    if treat_message(conn, messenger_id, user_msg, nil) == :error, do: IO.puts("Messenger error : can't treat message")
    send_resp(conn, 200, "ok")
  end

  # ---------------------------- ANSWER TO MESSAGE -------------------------------------

  defp treat_message(conn, messenger_id, user_msg, origin) do
    conversation = Members.get_or_initiate_conversation("messenger", messenger_id, nil, origin)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: user_msg}
      |> BotDecisions.call_bot_algorythm()

    case Members.update_conversation(conversation, results.conversation) do
      {:ok, _} ->
        # IO.inspect(results)
        mockable(MessengerApi).send_message("RESPONSE", conversation.psid, results.messages.message, results.messages.quick_replies, results.messages.buttons, nil)
        Enum.map(results.messages.offers, fn map -> mockable(MessengerApi).send_message("RESPONSE", conversation.psid, map.message, nil, nil, map.offer) end)
        :ok
      {:error, changeset} ->
        IO.inspect(changeset)
        :error
    end
  end

end
