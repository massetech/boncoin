defmodule BoncoinWeb.MessengerController do
  use BoncoinWeb, :controller
  import Mockery.Macro
  alias Boncoin.{Members, MessengerApi}
  alias Boncoin.CustomModules.BotDecisions

  # ---------------------------- CALLBACKS -------------------------------------

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

  # Welcome message when a user opens a new conversation
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD"},"sender" => %{"id" => messenger_id}}]}], "object" => "page"}) do
    IO.puts("#{messenger_id} opened a new conversation at #{Timex.now()}")

    # Treat the message
    messenger_name = MessengerApi.get_user_profile(messenger_id)
    conversation = Members.get_or_initiate_conversation("messenger", messenger_id, messenger_name)
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: nil}
      |> BotDecisions.call_bot_algorythm()

    # Send message to the visitor
    case Members.update_conversation(conversation, %{scope: results.scope, language: results.language}) do
      {:ok, _} -> mockable(MessengerApi).send_message(messenger_id, List.first(results.messages))
      {:error, _changeset} -> IO.puts("Messenger error : can't initiate conversation")
    end

    send_resp(conn, 200, "ok")
  end


  # Treat a valid text message comming from the user
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}], "object" => "page"}) do
    IO.puts("User #{messenger_id} spoke at #{Timex.now()}")

    # Treat the message
    conversation = Members.get_or_initiate_conversation("messenger", messenger_id, "")
    results = %{user: conn.assigns.current_user, conversation: conversation, announce: nil, user_msg: user_msg}
      |> BotDecisions.call_bot_algorythm()

    # Send response
    if results.scope == "close" do
      case Members.delete_conversation(conversation) do
        {:ok, _} -> Enum.map(results.messages, fn message -> mockable(MessengerApi).send_message(messenger_id, message) end)
        {:error, _changeset} -> IO.puts("Messenger error : can't delete conversation #{conversation.id}")
      end
    else
      case Members.update_conversation(conversation, %{scope: results.scope, language: results.language}) do
        {:ok, _} -> Enum.map(results.messages, fn message -> mockable(MessengerApi).send_message(messenger_id, message) end)
        {:error, _changeset} -> IO.puts("Messenger error : can't update conversation #{conversation.id}")
      end
    end

    send_resp(conn, 200, "ok")
  end

end
