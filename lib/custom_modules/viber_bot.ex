defmodule Boncoin.CustomModules.ViberBot do
  alias BoncoinWeb.LayoutView
  alias Boncoin.{Members, Contents}
  @website_url "https://www.pawchaungkaung.com"
  @website_url_form "https://www.pawchaungkaung.com/announces/new"

  # -------------------- DECISION  -------------------------------

  def call_bot_algorythm(%{tracking_data: tracking_data, announce: announce, params: %{user: user, language: language, viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}} = bot_params) do
    # IO.puts("Bot params")
    # IO.inspect(bot_params)

    cond do

      # We are waiting for a LANGUAGE
      tracking_data == "language" ->
        case user do
          nil -> # User unknown : we were waiting the user language input
            case language do
              nil -> [treat_msg("welcome")] # User didn't give his language, ask again
              _ -> [treat_msg("ask_phone", language)] # User gave his language
            end
          _ -> # User known : if different language then update
            if user.language != language do
              user = case Members.update_user(user, %{language: language}) do
                {:error, _} -> user
                {:ok, new_user} -> new_user
              end
            end
            [treat_msg("nothing_to_say", user)]
        end

      # We are waiting for a NEW PHONE NUMBER to create the user
      tracking_data == "link_phone" ->
        case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
          false -> [treat_msg("repeat_phone", language)] # There is no phone number in the message : ask again for it
          true -> # There is a phone number in the message
            phone_number = user_msg
            other_user = Members.get_other_user_by_phone_number(phone_number)
            case other_user do
              nil -> # The phone number is not used yet : create the user with this phone number
                case Members.create_user(%{phone_number: phone_number, viber_active: true, viber_id: viber_id, nickname: viber_name, language: language}) do
                  {:ok, new_user} -> [treat_msg("new_user_created", new_user)]
                  _ -> [treat_msg("technical problem", language)]
                end
              other_user -> manage_phone_number_conflicts(nil, other_user, phone_number, viber_id, viber_name, language, "link_phone") # The phone number is already used : check the rights
            end
        end

      # We send a NOTIFICATION to user
      tracking_data == "offer_treated" ->
        case announce.status do
          "ONLINE" -> [treat_msg("announce_accepted", user, announce, build_announce_view_link(announce))]
          "REFUSED" -> [treat_msg("announce_refused", user, announce)]
        end

      # User wants to CHANGE LANGUAGE
      tracking_data == "change_language" -> [treat_msg("change_language", user)]

      # User wants to see his OFFERS LIST
      tracking_data == "list_offers" ->
        offers = Contents.get_user_offers(user)
        case Kernel.length(offers) do
          0 -> [treat_msg("0_active_offer", user)]
          nb_offers ->
            msg = Enum.map(offers, fn offer -> build_detail_offer(user, offer) end)
            [treat_msg("nb_active_offers", user, nb_offers) | msg]
        end

      # User wants to UPDATE PHONE NUMBER
      tracking_data == "change_phone" -> [treat_msg("change_phone", user)]

      # User confirms to UPDATE PHONE NUMBER
      tracking_data == "update_phone" ->
        case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
        false -> [treat_msg("wrong_phone_number", user)] # There is no phone number in the message : cancel the update
        true -> # There is a phone number in the message
          # IO.puts("Phone number updating from Viber")
          phone_number = user_msg
          other_user = Members.get_other_user_by_phone_number(phone_number)
          cond do
            user.phone_number == user_msg -> [treat_msg("same_phone_number", user)] # Same phone number then user old one
            other_user == nil -> # The phone number is not used yet : update the user phone number
              case Members.update_user(user, %{phone_number: phone_number, nickname: viber_name, language: language}) do
                {:ok, user} -> [treat_msg("new_phone_updated", user)]
                _ -> [treat_msg("technical problem", language)]
              end
            true -> manage_phone_number_conflicts(user, other_user, phone_number, nil, nil, nil, "udate_phone") # The phone number is already used : check the rights
          end
        end

      # User is quitting Viber
      tracking_data == "quit_viber" ->
        # answer = Members.unlink_viber(user.phone_number)
        answer = Members.remove_viber_id(user)
        case answer do
          {:ok, user} -> [treat_msg("quit_viber", user)]
          {:error, _msg} -> [treat_msg("cannot_quit_viber", user)]
        end

      # We are waiting nothing (fallback)
      true ->
        cond do
          user == nil -> [treat_msg("repeat_phone", language)] # The user is not recognized : return to phone demand
          tracking_data == nil && user_msg == "0" -> [treat_msg("propose_help", user)] # User asked for help
          true -> [treat_msg("nothing_to_say", user)] # Nothing to say
        end

    end
  end

  def manage_phone_number_conflicts(user, other_user, phone_number, viber_id, user_name, language, tracking_data) do
    # This loop can be used with or without user
    cond do
      other_user. viber_active == true -> [treat_msg("viber_conflict_contact_us", language, user_name)] # 2 Vibers for the same account : contact us
      # Rules removed to let a user link to Viber even if there is some announces
      # other_user.nb_announces > 0 -> treat_msg("wait_for_no_more_offers", language, user_name, other_user.nb_announces) # The new phone number has active offers : wait until there is no more
      # other_user.nb_announces == 0 &&
      tracking_data == "link_phone" -> # The phone is not linked to viber and has no announce yet : use it to create new user
        other_user = Members.get_user!(other_user.id)
        case Members.update_user(other_user, %{viber_active: true, viber_id: viber_id, nickname: user_name, language: language}) do
          {:ok, user} -> [treat_msg("new_phone_updated", user)]
          _ -> [treat_msg("technical problem", language)]
        end
      # other_user.nb_announces == 0 &&
      tracking_data == "udate_phone" -> # The new phone is not linked to viber and has no announce yet : update the user phone number
        # Known user phone update
        case Members.delete_user(other_user) do
          {:ok, _} ->
            case Members.update_user(user, %{phone: phone_number}) do
              {:updated, user} -> [treat_msg("new_phone_updated", user)]
              _ -> [treat_msg("technical problem", language)]
            end
          _ -> [treat_msg("technical problem", language)]
        end
    end
  end

  # Build link for the user
  defp build_detail_offer(user, offer) do
    treat_msg("detail_active_offer", user, offer, build_announce_view_link(offer))
  end

  defp build_announce_view_link(announce) do
    "/offers/#{announce.safe_link}"
  end

  # -------------------- MESSAGES   -------------------------------

  # User is not known
  def treat_msg("welcome") do %{tracking_data: "language", msg: welcome_msg()} end
  def treat_msg("ask_phone", language) do %{tracking_data: "link_phone_#{language}", msg: ask_phone_msg(language)} end
  def treat_msg("repeat_phone", language) do %{tracking_data: "link_phone_#{language}", msg: ask_again_phone_msg(language)} end
  def treat_msg("technical problem", language) do %{tracking_data: "link_phone_#{language}", msg: announce_technical_error(language)} end
  def treat_msg("viber_conflict_contact_us", language, user_name) do %{tracking_data: nil, msg: announce_viber_account_conflict(language, user_name)} end

  # User is  known
  def treat_msg("new_user_created", user) do %{tracking_data: nil, msg: confirm_user_created(user.language, user.nickname)} end
  def treat_msg("welcome_back", user) do %{tracking_data: nil, msg: welcome_back_msg(user.language, user.nickname)} end
  def treat_msg("nothing_to_say", user) do %{tracking_data: nil, msg: nothing_to_say_msg(user.language, user.nickname)} end
  def treat_msg("announce_accepted", user, announce, link) do %{tracking_data: nil, msg: tell_offer_accepted(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_refused", user, announce) do %{tracking_data: nil, msg: tell_offer_refused(user.language, user.nickname, announce.title, announce.cause)} end
  def treat_msg("propose_help", user) do %{tracking_data: "help", msg: inform_help(user.language, user.nickname)} end
  def treat_msg("change_language", user) do %{tracking_data: "language", msg: change_language_msg(user.language, user.nickname)} end
  def treat_msg("change_phone", user) do %{tracking_data: "update_phone", msg: alert_before_phone_update(user.language, user.nickname)} end
  def treat_msg("wrong_phone_number", user) do %{tracking_data: nil, msg: inform_wrong_phone_number(user.language, user.nickname)} end
  def treat_msg("same_phone_number", user) do %{tracking_data: nil, msg: tell_same_phone_number(user.language, user.nickname)} end
  def treat_msg("new_phone_updated", user) do %{tracking_data: nil, msg: confirm_new_phone_number_updated(user.language, user.nickname)} end

  def treat_msg("quit_viber", user) do %{tracking_data: nil, msg: tell_viber_quitted(user.language, user.nickname)} end
  def treat_msg("cannot_quit_viber", user) do %{tracking_data: nil, msg: tell_viber_cannot_quit(user.language, user.nickname)} end
  def treat_msg("0_active_offer", user) do %{tracking_data: nil, msg: tell_no_active_offer(user.language, user.nickname)} end
  def treat_msg("nb_active_offers", user, nb_offers) do %{tracking_data: nil, msg: tell_nb_active_offers(user.language, user.nickname, nb_offers)} end
  def treat_msg("detail_active_offer", user, offer, link) do %{tracking_data: nil, msg: detail_active_offers(user.language, offer.title, LayoutView.format_date(offer.validity_date), link)} end

  defp welcome_msg() do
    "Welcome to Pawchaungkaung !\nWhat is your language ?\n  -> ျမမ္မားစာအတြက္ [1] ႏွိပ္ပါ \n  -> မြမ်မားစာအတွက် [2] နှိပ်ပါ \n  -> For English send [3]"
  end

  defp change_language_msg(language, nickname) do
    case language do
      _ -> "Please choose your language\n  -> ျမမ္မားစာအတြက္ [1] ႏွိပ္ပါ \n  -> မြမ်မားစာအတွက် [2] နှိပ်ပါ \n  -> For English send [3]"
    end
  end

  defp change_phone_msg(language, nickname) do
    case language do
      _ -> "Please choose your language\n  -> ျမမ္မားစာအတြက္ [1] ႏွိပ္ပါ \n  -> မြမ်မားစာအတွက် [2] နှိပ်ပါ \n  -> For English send [3]"
    end
  end

  defp welcome_back_msg(language, nickname) do
    case language do
      _ -> "Welcome back to Pawchaungkaung #{nickname} !\n\nPlease visit us on #{@website_url}\n\nFor help please send [0]"
    end
  end

  defp nothing_to_say_msg(language, nickname) do
    case language do
      _ -> "Hi #{nickname} ! #{say_something_neutral(language)}\n\nPlease visit us on #{@website_url}\n\nFor help please send [0]"
    end
  end

  defp ask_phone_msg(language) do
    case language do
      _ -> "Now we can speak! Please also type your mobile phone number."
    end
  end

  defp ask_again_phone_msg(language) do
    case language do
      _ -> "Sorry but we need to identify you. Please type your mobile phone number."
    end
  end

  defp inform_wrong_phone_number(language, nickname) do
    case language do
      _ -> "Sorry #{nickname}, this is not a good phone number. To try again please type [*888#]."
    end
  end

  defp alert_before_phone_update(language, nickname) do
    case language do
      _ -> "All your offers will be moved to this new phone number. If you are sure please type your new phone number now.\n"
    end
  end

  defp confirm_user_created(language, nickname) do
    case language do
      _ -> "Cool #{nickname}! Your phone number and viber account are now linked.\n Please visit us on #{@website_url}"
    end
  end

  defp tell_same_phone_number(language, nickname) do
    case language do
      _ -> "You know what #{nickname}, your phone number was already linked to this viber account :)"
    end
  end

  defp confirm_new_phone_number_updated(language, nickname) do
    case language do
      _ -> "Perfect #{nickname}, your phone number was updated.\n Please visit us on #{@website_url}"
    end
  end

  defp announce_phone_used(language) do
    case language do
      _ -> "Sorry but this phone number is linked to another Viber user. Please unlink it first on #{@website_url_form} or contact us."
    end
  end

  defp announce_technical_error(language) do
    case language do
      _ -> "Sorry we have a technical problem."
    end
  end

  defp announce_viber_account_conflict(language, nickname) do
    case language do
      _ -> "Sorry #{nickname}, this phone number is linked to another Viber user. Please unlink it first on #{@website_url_form} or contact us."
    end
  end

  defp inform_help(language, nickname) do
    case language do
      _ -> "We are happy to help #{nickname},\n\nchange language [*123#]\nsee your offers [*111#]\nchange phone number [*888#]\nquit Viber [*999#]"
    end
  end

  defp tell_offer_accepted(language, nickname, title, validity_date, link) do
    case language do
      _ -> "Hi #{nickname}, your offer #{title} is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
    end
  end

  defp tell_offer_refused(language, nickname, title, cause) do
    case language do
      _ -> "Hi #{nickname}, we are sorry but your offer #{title} was refused because #{cause}. \nPlease create a new one on #{@website_url_form}"
    end
  end

  defp tell_viber_quitted(language, nickname) do
    case language do
      _ -> "Your Viber account has been unlinked.\nHope to see you soon on #{@website_url}"
    end
  end

  defp tell_viber_cannot_quit(language, nickname) do
    case language do
      _ -> "Sorry #{nickname} but we cannot unlink your Viber. Please contact us."
    end
  end

  defp tell_no_active_offer(language, nickname) do
    case language do
      _ -> "Hey #{nickname}, you dont any offer yet. Please create one on #{@website_url_form}"
    end
  end

  defp tell_nb_active_offers(language, nickname, nb_offers) do
    case language do
      _ -> "Ok #{nickname}, you have #{nb_offers} active offers."
    end
  end

  defp detail_active_offers(language, title, validity_date, link) do
    case language do
      _ -> "#{title}\nActive until #{validity_date}.\nSee it on #{@website_url}#{link}"
    end
  end

  defp say_something_neutral(language) do
    case Enum.random([1, 2, 3, 4, 5]) do
      1 -> case language do
          _ -> ""
        end
      2 -> case language do
          _ -> "Hope you are fine !"
        end
      3 -> case language do
          _ -> "What's up ?"
        end
      4 -> case language do
          _ -> "Searching something ?"
        end
      5 -> case language do
          _ -> "Selling something ?"
        end
    end
  end

end
