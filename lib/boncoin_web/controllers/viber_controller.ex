defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members}
  alias Boncoin.CustomModules.BotMessages

  # Connect to Webhook
  def connect(conn, _params) do
    IO.puts("Connect to Viber Webhook asked")
    params = %{
      url: System.get_env("VIBER_API_URL"),
      event_types: ["delivered", "failed", "subscribed", "unsubscribed", "conversation_started"],
      send_name: true,
      send_photo: false
    }
    ViberApi.post("set_webhook", params)
    conn
      |> redirect(to: root_path(conn, :welcome))
  end

  # Disconnect of Webhook
  def disconnect(conn, _params) do
    IO.puts("Disconnect from Viber Webhook")
    ViberApi.post("set_webhook", %{url: ""})
    conn
      |> redirect(to: root_path(conn, :welcome))
  end

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
    {tracking_data, message} = case conn.assigns.current_user do
      nil -> BotMessages.treat_msg("welcome")
      user -> BotMessages.treat_msg("welcome_back", user)
    end
    sender = get_sender()
    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: sender, message: message, tracking_data: tracking_data)
  end

  # Receive a message from the user with tracking_data
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => user_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")

    # Preparing datas depending on msg scope
    tracking_data = params["message"]["tracking_data"] || nil
    user = conn.assigns.current_user
    if user != nil, do: language = user.language, else: language = nil
    cond do
      tracking_data == "language" && Enum.member?(["1", "2", "3"], String.slice(user_msg,0,1)) ->
        language = case String.slice(user_msg,0,1) do
          "1" -> "mr"
          "2" -> "mm"
          "3" -> "en"
        end
      # tracking_data == "language" -> language = nil
      Enum.member?(["link_phone_mr", "link_phone_mm", "link_phone_en"], tracking_data) == true ->
        language = String.replace(tracking_data, "link_phone_", "")
        tracking_data = "link_phone"
      true ->
        # Fallback for language asking if we still dont know the user (user lost)
        case user do
          nil -> tracking_data = "language"
          _ -> tracking_data
        end
    end
    # Inspect msg params
    IO.puts("Bot params")
    %{tracking_data: tracking_data, user: user, language: language, user_msg: user_msg} |> IO.inspect()

    # Bot reaction algorythm
    IO.puts("Bot reaction algorythm")
    {tracking_data, message} = cond do
      # We are waiting for a language answer
      tracking_data == "language" ->
        IO.puts("Asking user for his language")
        cond do
          user != nil -> BotMessages.treat_msg("nothing_to_say", user) # Nothing to do
          true -> # We were waiting the user language
            case language do
              nil -> {tracking_data, message} = BotMessages.treat_msg("welcome") # User didn't give his language, ask again
              language -> {tracking_data, message} = BotMessages.treat_msg("ask_phone", language) # User gave his language
            end
        end

      # We are waiting for a phone answer
      tracking_data == "link_phone" ->
        cond do
          user != nil -> BotMessages.treat_msg("nothing_to_say", user) # Nothing to do
          true -> # We were waiting the phone number
            case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
              false -> BotMessages.treat_msg("repeat_phone", language) # There is no phone number in the message : ask again for it
              true -> # There is a phone number in the message
                IO.puts("New Viber user creating")
                phone_number = user_msg
                other_user = Members.get_other_user_by_phone_number(phone_number)
                case other_user do
                  nil -> # The phone number is not used yet : create the user with this phone number
                    case Members.create_user(%{phone_number: phone_number, viber_active: true, viber_id: viber_id, nickname: user_name, language: language}) do
                      {:ok, user} -> {tracking_data, message} = BotMessages.treat_msg("new_user_created", user)
                      _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
                    end
                  other_user -> manage_phone_number_conflicts(nil, other_user, phone_number, viber_id, user_name, language, "link_phone") # The phone number is already used : check the rights
                end
            end
        end

      # We are waiting for a NEW phone number
      tracking_data == "update_phone" ->
        case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
          false -> BotMessages.treat_msg("wrong_phone_number", user) # There is no phone number in the message : cancel the update
          true -> # There is a phone number in the message
            IO.puts("Phone number updating from Viber")
            phone_number = user_msg
            other_user = Members.get_other_user_by_phone_number(phone_number)
            cond do
              user.phone_number == user_msg -> BotMessages.treat_msg("same_phone_number", user) # Same phone number then user old one
              other_user == nil -> # The phone number is not used yet : update the user phone number
                case Members.update_user(user, %{phone_number: phone_number, nickname: user_name, language: language}) do
                  {:ok, user} -> {tracking_data, message} = BotMessages.treat_msg("new_phone_updated", user)
                  _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
                end
              true -> manage_phone_number_conflicts(user, other_user, phone_number, nil, nil, nil, "udate_phone") # The phone number is already used : check the rights
            end
        end

      # We are waiting nothing (fallback)
      true ->
        IO.puts("Nothing to say to Viber")
        cond do
          user == nil -> BotMessages.treat_msg("repeat_phone", language) # The user is not recognized : return to phone demand
          user_msg == "CHANGE" -> BotMessages.treat_msg("propose_phone_update", user) # The user wants to change his phone
          true -> {tracking_data, message} = BotMessages.treat_msg("nothing_to_say", user) # Nothing to say
        end

    end

    # Send datas to viber API
    data = %{
      sender: get_sender(),
      receiver: viber_id,
      type: "text",
      tracking_data: tracking_data,
      text: message
    }
    ViberApi.post("send_message", data)
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

  defp get_sender() do
    %{name: "PawChaungKaung", avatar: ""}
  end

  defp manage_phone_number_conflicts(user, other_user, phone_number, viber_id, user_name, language, tracking_data) do
    # This loop can be used with or without user
    cond do
      other_user. viber_active == true -> BotMessages.treat_msg("viber_conflict_contact_us", language, user_name) # 2 Vibers for the same account : contact us
      other_user.nb_active_announce > 0 -> BotMessages.treat_msg("wait_for_no_more_offers", language, user_name, other_user.nb_active_announce) # The new phone number has active offers : wait until there is no more
      other_user.nb_active_announce == 0 && tracking_data == "link_phone" -> # The phone is not linked to viber and has no announce yet : use it to create new user
        # New user creation
        case Members.delete_user(other_user) do
          {:ok, _} ->
            case Members.create_user(%{phone: phone_number, viber_active: true, viber_id: viber_id, nickname: user_name, language: language}) do
              {:created, user} -> {tracking_data, message} = BotMessages.treat_msg("new_phone_updated", user)
              _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
            end
          _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
        end
      other_user.nb_active_announce == 0 && tracking_data == "udate_phone" -> # The new phone is not linked to viber and has no announce yet : update the user phone number
        # Known user phone update
        case Members.delete_user(other_user) do
          {:ok, _} ->
            case Members.update_user(user, %{phone: phone_number}) do
              {:updated, user} -> {tracking_data, message} = BotMessages.treat_msg("new_phone_updated", user)
              _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
            end
          _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
        end
    end
  end

  # defp get_msg(params) do
  #   case params do
  #     "welcome" ->
  #       "Welcome to PawChaungKaung ! Please send us your connection code or your phone number...\n****\nောသဟယ်\n****\nစစ္ကုိင္းတုိင္း ေဒသႀကီးတြင္"
  #     _ -> "pb"
  #   end
  # end


end
