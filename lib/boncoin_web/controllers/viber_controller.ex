defmodule BoncoinWeb.ViberController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Members, Contents}
  alias Boncoin.CustomModules.BotMessages

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
    # |> IO.inspect()
    # System.get_env("VIBER_SECRET")
    # |> IO.inspect()
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
      nil -> BotMessages.treat_msg("welcome")
      user -> BotMessages.treat_msg("welcome_back", user)
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
    # Set up default variables
    tracking_data = params["message"]["tracking_data"] || nil
    language = nil

    # Set up user
    user = conn.assigns.current_user
    if user == nil do
      if tracking_data == nil, do: tracking_data = "language" # Fallback for language scope if any problem
    end

    # Detect the choosen language in language scope
    if tracking_data == "language" do
      msg_first_key = String.slice(user_msg,0,1)
      if Enum.member?(["1", "2", "3"], msg_first_key), do: language = convert_language(msg_first_key)
    end

    # Detect the language in phone scope
    if Enum.member?(["link_phone_mr", "link_phone_my", "link_phone_en"], tracking_data) == true do
      language = String.replace(tracking_data, "link_phone_", "")
      tracking_data = "link_phone"
    end

    # Call bot algorythm and send the resulting messages to viber API
    bot_datas = %{tracking_data: tracking_data, details: %{user: user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}, announce: %{}}
      |> call_bot_algorythm()
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

  defp convert_language(code) do
    case code do
      "1" -> "mr"
      "2" -> "my"
      "3" -> "en"
    end
  end

  # Viber msg signature
  def build_sender() do
    %{name: "PawChaungKaung", avatar: ""}
  end

  # Build link for the user
  def build_announce_view_link(announce) do
    "/offers/#{announce.safe_link}"
    # "/offers?search[township_id]=#{announce.township_id}&search[category_id]=#{announce.category_id}"
  end

  defp build_detail_offer(user, offer) do
    BotMessages.treat_msg("detail_active_offer", user, offer, build_announce_view_link(offer))
  end

  # -------------------- Bot reaction algorythm   -------------------------------

  def call_bot_algorythm(%{tracking_data: tracking_data, details: %{user: user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}, announce: announce} = bot_params) do
    IO.puts("Bot params")
    bot_params
    |> IO.inspect()
    cond do

    # User asks to change language
    tracking_data == nil && user_msg == "0" && user != nil ->
      [BotMessages.treat_msg("welcome")]

    # We are waiting for a language answer
    tracking_data == "language" ->
      # IO.puts("Treating Viber msg in Language scope")
      cond do
        user != nil ->
          if user.language != language do
            user = case Members.update_user(user, %{language: language}) do
              {:error, _} -> user
              {:ok, new_user} -> new_user
            end
          end
          [BotMessages.treat_msg("nothing_to_say", user)]
        true -> # User unknown : we were waiting the user language input
          case language do
            nil -> [BotMessages.treat_msg("welcome")] # User didn't give his language, ask again
            _ -> [BotMessages.treat_msg("ask_phone", language)] # User gave his language
          end
      end

    # We are waiting for a phone number to create the user
    tracking_data == "link_phone" ->
      cond do
        user != nil -> [BotMessages.treat_msg("nothing_to_say", user)] # Nothing to do
        true -> # We were waiting the phone number
          case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
            false -> [BotMessages.treat_msg("repeat_phone", language)] # There is no phone number in the message : ask again for it
            true -> # There is a phone number in the message
              # IO.puts("New Viber user creating")
              phone_number = user_msg
              other_user = Members.get_other_user_by_phone_number(phone_number)
              case other_user do
                nil -> # The phone number is not used yet : create the user with this phone number
                  case Members.create_user(%{phone_number: phone_number, viber_active: true, viber_id: viber_id, nickname: viber_name, language: language}) do
                    {:ok, new_user} -> [BotMessages.treat_msg("new_user_created", new_user)]
                    _ -> [BotMessages.treat_msg("technical problem", language)]
                  end
                other_user -> manage_phone_number_conflicts(nil, other_user, phone_number, viber_id, viber_name, language, "link_phone") # The phone number is already used : check the rights
              end
          end
      end

    # User asked for help
    String.downcase(user_msg) == "help" && user != nil ->
      [BotMessages.treat_msg("give_help", user)]

    # We are waiting for a NEW phone number
    tracking_data == "update_phone" && user != nil ->
      case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
        false -> [BotMessages.treat_msg("wrong_phone_number", user)] # There is no phone number in the message : cancel the update
        true -> # There is a phone number in the message
          # IO.puts("Phone number updating from Viber")
          phone_number = user_msg
          other_user = Members.get_other_user_by_phone_number(phone_number)
          cond do
            user.phone_number == user_msg -> [BotMessages.treat_msg("same_phone_number", user)] # Same phone number then user old one
            other_user == nil -> # The phone number is not used yet : update the user phone number
              case Members.update_user(user, %{phone_number: phone_number, nickname: viber_name, language: language}) do
                {:ok, user} -> [BotMessages.treat_msg("new_phone_updated", user)]
                _ -> [BotMessages.treat_msg("technical problem", language)]
              end
            true -> manage_phone_number_conflicts(user, other_user, phone_number, nil, nil, nil, "udate_phone") # The phone number is already used : check the rights
          end
        end

    # This is an automatic message
    tracking_data == "offer_treated" && user != nil ->
      cond do
        # announce.status == "ONLINE" && announce.cause == "moved"
        #   -> BotMessages.treat_msg("announce_moved", user, announce, build_announce_view_link(announce))
        # announce.status == "ONLINE" && announce.cause == "accepted" ->
        announce.status == "ONLINE" ->
          [BotMessages.treat_msg("announce_accepted", user, announce, build_announce_view_link(announce))]
        announce.status == "REFUSED" ->
          [BotMessages.treat_msg("announce_refused", user, announce)]
      end

    # User is quitting Viber
    # tracking_data == "viber_removed" -> BotMessages.treat_msg("quit_viber", user)
    tracking_data == nil && user_msg == "999#" && user != nil ->
      # answer = Members.unlink_viber(user.phone_number)
      answer = Members.remove_viber_id(user)
      case answer do
        {:ok, user} -> [BotMessages.treat_msg("quit_viber", user)]
        {:error, _msg} -> [BotMessages.treat_msg("cannot_quit_viber", user)]
      end

    # User wants to see his active offers
    tracking_data == nil && user_msg == "123#" && user != nil ->
      offers = Contents.get_user_offers(user)
      case Kernel.length(offers) do
        0 -> [BotMessages.treat_msg("0_active_offer", user)]
        nb_offers ->
          msg = Enum.map(offers, fn offer -> build_detail_offer(user, offer) end)
          [BotMessages.treat_msg("nb_active_offers", user, nb_offers) | msg]
      end

    # User wants to update his phone number
    tracking_data == nil && user_msg == "000#" && user != nil ->
      [BotMessages.treat_msg("propose_phone_update", user)] # The user wants to change his phone

    # We are waiting nothing (fallback)
    true ->
      IO.puts("Nothing to say to Viber")
      cond do
        user == nil -> [BotMessages.treat_msg("repeat_phone", language)] # The user is not recognized : return to phone demand
        true -> [BotMessages.treat_msg("nothing_to_say", user)] # Nothing to say
      end
    end
  end

  def manage_phone_number_conflicts(user, other_user, phone_number, viber_id, user_name, language, tracking_data) do
    # This loop can be used with or without user
    cond do
      other_user. viber_active == true -> [BotMessages.treat_msg("viber_conflict_contact_us", language, user_name)] # 2 Vibers for the same account : contact us
      # Rules removed to let a user link to Viber even if there is some announces
      # other_user.nb_announces > 0 -> BotMessages.treat_msg("wait_for_no_more_offers", language, user_name, other_user.nb_announces) # The new phone number has active offers : wait until there is no more
      # other_user.nb_announces == 0 &&
      tracking_data == "link_phone" -> # The phone is not linked to viber and has no announce yet : use it to create new user
        other_user = Members.get_user!(other_user.id)
        case Members.update_user(other_user, %{viber_active: true, viber_id: viber_id, nickname: user_name, language: language}) do
          {:ok, user} -> [BotMessages.treat_msg("new_phone_updated", user)]
          _ -> [BotMessages.treat_msg("technical problem", language)]
        end
      # other_user.nb_announces == 0 &&
      tracking_data == "udate_phone" -> # The new phone is not linked to viber and has no announce yet : update the user phone number
        # Known user phone update
        case Members.delete_user(other_user) do
          {:ok, _} ->
            case Members.update_user(user, %{phone: phone_number}) do
              {:updated, user} -> [BotMessages.treat_msg("new_phone_updated", user)]
              _ -> [BotMessages.treat_msg("technical problem", language)]
            end
          _ -> [BotMessages.treat_msg("technical problem", language)]
        end
    end
  end

end
