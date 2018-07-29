defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members}
  alias Boncoin.CustomModules.BotMessages

# ---------------------------- CONNECTION -------------------------------------

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
    {tracking_data, message} = case conn.assigns.current_user do
      nil -> BotMessages.treat_msg("welcome")
      user -> BotMessages.treat_msg("welcome_back", user)
    end
    sender = build_sender()
    conn
      |> put_status(:ok)
      |> render("send_message.json", sender: sender, message: message, tracking_data: tracking_data)
  end

  # Receive a message from the user with tracking_data
  def callback(conn, %{"event" => "message", "timestamp" => timestamp, "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}} = params) do
    IO.puts("User #{viber_id} spoke at #{timestamp}")

    # Prepare datas depending on msg scope
    tracking_data = params["message"]["tracking_data"] || nil
    db_user = conn.assigns.current_user
    if db_user != nil, do: language = db_user.language, else: language = nil
    cond do
      tracking_data == "language" && Enum.member?(["1", "2", "3"], String.slice(user_msg,0,1)) ->
        language = case String.slice(user_msg,0,1) do
          "1" -> "mr"
          "2" -> "mm"
          "3" -> "en"
        end
      Enum.member?(["link_phone_mr", "link_phone_mm", "link_phone_en"], tracking_data) == true ->
        language = String.replace(tracking_data, "link_phone_", "")
        tracking_data = "link_phone"
      true ->
        # Fallback for language asking if we still dont know the user (user lost)
        case db_user do
          nil -> tracking_data = "language"
          _ -> tracking_data
        end
    end

    # Call bot algorythm
    bot_datas = %{tracking_data: tracking_data, user: %{db_user: db_user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}, announce: %{}}
    {tracking_data, message} = call_bot_algorythm(bot_datas)

    # Send the answer to viber API
    send_viber_message(viber_id, tracking_data, message)

    # Confirm to Viber the msg was received
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

  # Build link for the user
  def build_announce_view_link(announce) do
    "https://pawchaungkaung.asia/offers?search[township_id]=#{announce.township_id}&search[category_id]=#{announce.category_id}"
  end


  # Bot reaction algorythm
  def call_bot_algorythm(%{tracking_data: tracking_data, user: %{db_user: db_user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}, announce: announce} = bot_params) do
    IO.puts("Bot params")
    bot_params |> IO.inspect()

    cond do
    # We are waiting for a language answer
    tracking_data == "language" ->
      IO.puts("Asking user for his language")
      cond do
        db_user != nil -> BotMessages.treat_msg("nothing_to_say", db_user) # Nothing to do
        true -> # We were waiting the user language
          case language do
            nil -> {tracking_data, message} = BotMessages.treat_msg("welcome") # User didn't give his language, ask again
            language -> {tracking_data, message} = BotMessages.treat_msg("ask_phone", language) # User gave his language
          end
      end

    # We are waiting for a phone answer
    tracking_data == "link_phone" ->
      cond do
        db_user != nil -> BotMessages.treat_msg("nothing_to_say", db_user) # Nothing to do
        true -> # We were waiting the phone number
          case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
            false -> BotMessages.treat_msg("repeat_phone", language) # There is no phone number in the message : ask again for it
            true -> # There is a phone number in the message
              IO.puts("New Viber user creating")
              phone_number = user_msg
              other_user = Members.get_other_user_by_phone_number(phone_number)
              case other_user do
                nil -> # The phone number is not used yet : create the user with this phone number
                  case Members.create_user(%{phone_number: phone_number, viber_active: true, viber_id: viber_id, nickname: viber_name, language: language}) do
                    {:ok, new_user} -> {tracking_data, message} = BotMessages.treat_msg("new_user_created", new_user)
                    _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
                  end
                other_user -> manage_phone_number_conflicts(nil, other_user, phone_number, viber_id, viber_name, language, "link_phone") # The phone number is already used : check the rights
              end
          end
      end

    # We are waiting for a NEW phone number
    tracking_data == "update_phone" ->
      case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
        false -> BotMessages.treat_msg("wrong_phone_number", db_user) # There is no phone number in the message : cancel the update
        true -> # There is a phone number in the message
          IO.puts("Phone number updating from Viber")
          phone_number = user_msg
          other_user = Members.get_other_user_by_phone_number(phone_number)
          cond do
            db_user.phone_number == user_msg -> BotMessages.treat_msg("same_phone_number", db_user) # Same phone number then user old one
            other_user == nil -> # The phone number is not used yet : update the user phone number
              case Members.update_user(db_user, %{phone_number: phone_number, nickname: viber_name, language: language}) do
                {:ok, db_user} -> {tracking_data, message} = BotMessages.treat_msg("new_phone_updated", db_user)
                _ -> {tracking_data, message} = BotMessages.treat_msg("technical problem", language)
              end
            true -> manage_phone_number_conflicts(db_user, other_user, phone_number, nil, nil, nil, "udate_phone") # The phone number is already used : check the rights
          end
      end

    # This is an automatic message
    tracking_data == "offer_treated" ->
      cond do
        announce.status == "ONLINE" && announce.cause == "moved"
          -> BotMessages.treat_msg("announce_moved", db_user, announce, build_announce_view_link(announce))
        announce.status == "ONLINE" && announce.cause == "accepted"
          -> BotMessages.treat_msg("announce_accepted", db_user, announce, build_announce_view_link(announce))
        announce.status == "REFUSED"
          -> BotMessages.treat_msg("announce_refused", db_user, announce)
      end

    # We are waiting nothing (fallback)
    true ->
      IO.puts("Nothing to say to Viber")
      cond do
        db_user == nil -> BotMessages.treat_msg("repeat_phone", language) # The user is not recognized : return to phone demand
        user_msg == "CHANGE" -> BotMessages.treat_msg("propose_phone_update", db_user) # The user wants to change his phone
        true -> {tracking_data, message} = BotMessages.treat_msg("nothing_to_say", db_user) # Nothing to say
      end
    end
  end

  def manage_phone_number_conflicts(user, other_user, phone_number, viber_id, user_name, language, tracking_data) do
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

end
