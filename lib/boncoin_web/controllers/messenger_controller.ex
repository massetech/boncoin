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

  # EVENT messaging_referrals (user opens a new conversation from link m.me or QR code)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"postback" => %{"referral" => %{"ref" => ref}}, "sender" => %{"id" => messenger_id}}]}]} = msg_query) do
    IO.puts("Messenger user  #{messenger_id} opened a new conversation at #{Timex.now()}")
    IO.puts("messaging_referrals, ref: #{ref}")
    msg = case treat_message(conn, messenger_id, nil, ref) do
      {:error, _} -> "Messenger error : can't open conversation (messaging_referrals)"
      {:ok, msg} -> msg
    end
    send_resp(conn, 200, msg)
  end

  # EVENT messaging_postbacks (user opens a new conversation directly from messenger)
  # Also used when user clicks on HELP : we also use the payload in user_msg for this case
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => user_msg}, "sender" => %{"id" => messenger_id}}]}]} = msg_query) do
    IO.puts("Messenger user  #{messenger_id} opened a new conversation at #{Timex.now()}, origin= #{user_msg}")
    IO.puts("messaging_postbacks, payload: #{user_msg}")
    msg = case treat_message(conn, messenger_id, user_msg, user_msg) do
      {:error, _} -> "Messenger error : can't open conversation (messaging_postbacks)"
      {:ok, msg} -> msg
    end
    send_resp(conn, 200, msg)
  end

  # EVENT message (user sends a quickreply)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"quick_reply" => %{"payload" => user_msg}}}]}]} = msg_query) do
    IO.puts("Messenger user #{messenger_id} spoke at #{Timex.now()}")
    IO.puts("messaging_quick_reply")
    if treat_message(conn, messenger_id, user_msg, "unknown") == :error, do: IO.puts("Messenger error : can't treat message")
    send_resp(conn, 200, "ok")
  end

  # EVENT message (user sends a normal message)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}]} = msg_query) do
    IO.puts("Messenger user #{messenger_id} spoke at #{Timex.now()}")
    IO.puts("messaging_message")
    msg = case treat_message(conn, messenger_id, user_msg, "unknown") do
      {:error, _} -> "Messenger error : can't treat message"
      {:ok, msg} -> msg
    end
    send_resp(conn, 200, msg)
  end

  # EVENT message (user returns to conversation from a me_link)
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"referral" => %{"ref" => ref}, "sender" => %{"id" => messenger_id}}]}]} = msg_query) do
    IO.puts("Messenger user #{messenger_id} spoke at #{Timex.now()}")
    IO.puts("messaging_return_me_link")
    msg = case treat_message(conn, messenger_id, "nothing", "unknown") do
      {:error, _} -> "Messenger error : can't treat message"
      {:ok, msg} -> msg
    end
    send_resp(conn, 200, msg)
  end


  # ---------------------------- ANSWER TO MESSAGE -------------------------------------

  defp treat_message(conn, messenger_id, user_msg, origin) do
    conversation = Members.get_or_initiate_conversation("messenger", messenger_id, nil, origin)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: user_msg}
      |> BotDecisions.call_bot_algorythm()

    case Members.update_conversation(conversation, results.conversation) do
      {:ok, _} ->
        mockable(MessengerApi).send_message("RESPONSE", conversation.psid, results.messages.message, results.messages.quick_replies, results.messages.buttons, nil)
        # Send the offers details
        Enum.map(results.messages.offers, fn map -> mockable(MessengerApi).send_message("RESPONSE", conversation.psid, map.message, nil, map.buttons, map.offer) end)
        {:ok, results.messages.message}
      {:error, changeset} ->
        IO.inspect(changeset)
        {:error, nil}
    end
  end

end
