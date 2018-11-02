defmodule BoncoinWeb.MessengerController do
  use BoncoinWeb, :controller
  alias Boncoin.{MessengerApi, Members}
  alias Boncoin.CustomModules.BotDecisions

  # ---------------------------- CALLBACKS -------------------------------------

  # Answer to Messenger to confirm the Webhook connection
  def callback(conn, %{"hub.mode" => mode, "hub.verify_token" => token, "hub.challenge" => challenge} = params) do
    IO.inspect(params)
    verify_token = System.get_env("MESSENGER_SECRET")
    if (mode == "subscribe" and token == verify_token) do
      IO.puts("Messenger webhook confirmed at #{Timex.now()}")
      send_resp(conn, 200, challenge)
    else
      send_resp(conn, 403, "Unauthorized")
    end
  end

  # Welcome message when a user opens a new conversation
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD"},"sender" => %{"id" => messenger_id}}]}], "object" => "page"}) do
    # Treat the message
    IO.puts("#{messenger_id} opened a new conversation at #{Timex.now()}")
    results = %{scope: "welcome", user: conn.assigns.current_user, announce: nil, bot: %{bot_provider: "messenger", bot_id: messenger_id, bot_user_name: nil, user_msg: nil}}
      |> BotDecisions.call_bot_algorythm()

    # Send message to welcome the visitor
    nickname = MessengerApi.get_user_profile(messenger_id)
    conv_params = %{bot_provider: "messenger", psid: messenger_id, scope: results.scope, nickname: nickname}
    case Members.create_or_update_conversation(conv_params) do
      {:ok, _} -> MessengerApi.send_message(messenger_id, List.first(results.messages))
      {:error, _changeset} -> IO.puts("Messenger error : can't initiate conversation")
    end

    send_resp(conn, 200, "ok")
  end


  # Treat a valid text message comming from the user
  def incoming_message(conn, %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}], "object" => "page"}) do
    # Treat the message
    IO.puts("User #{messenger_id} spoke at #{Timex.now()}")
    actual_conv = Members.get_actual_conversation_by_provider_psid("messenger", messenger_id)
    results = %{scope: actual_conv.scope, user: conn.assigns.current_user, announce: nil, bot: %{bot_provider: "messenger", bot_id: messenger_id, bot_user_name: actual_conv.nickname, user_msg: user_msg}}
      |> BotDecisions.call_bot_algorythm()

    # Answer to the user's message
    nickname = case actual_conv.nickname do
      "" -> MessengerApi.get_user_profile(messenger_id)
      nickname -> nickname
    end
    conv_params = %{bot_provider: "messenger", psid: messenger_id, scope: results.scope, nickname: nickname}
    case Members.create_or_update_conversation(conv_params) do
      {:ok, _} -> Enum.map(results.messages, fn message -> MessengerApi.send_message(messenger_id, message) end)
      {:error, _changeset} -> IO.puts("Messenger error : can't update conversation")
    end

    send_resp(conn, 200, "ok")
  end

end
