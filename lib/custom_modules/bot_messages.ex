defmodule Boncoin.CustomModules.BotMessages do
  alias Boncoin.Members
  alias BoncoinWeb.LayoutView
  @website_url "https://www.pawchaungkaung.com"
  @website_url_form "https://www.pawchaungkaung.com/announces/new"

  def treat_msg("welcome") do {"language", welcome_msg()} end
  def treat_msg("welcome_back", user) do {"language", welcome_back_msg(user.language, user.nickname)} end
  def treat_msg("nothing_to_say", user) do {nil, nothing_to_say_msg(user.language, user.nickname)} end
  def treat_msg("ask_phone", language) do {"link_phone_#{language}", ask_phone_msg(language)} end
  def treat_msg("repeat_phone", language) do {"link_phone_#{language}", ask_again_phone_msg(language)} end
  def treat_msg("wrong_phone_number", user) do {nil, inform_wrong_phone_number(user.language, user.nickname)} end
  def treat_msg("new_user_created", user) do {nil, confirm_user_created(user.language, user.nickname)} end
  def treat_msg("same_phone_number", user) do {nil, tell_same_phone_number(user.language, user.nickname)} end
  def treat_msg("propose_phone_update", user) do {"update_phone", alert_before_phone_update(user.language, user.nickname)} end
  def treat_msg("new_phone_updated", user) do {nil, confirm_new_phone_number_updated(user.language, user.nickname)} end
  def treat_msg("viber_conflict_contact_us", language, name) do {"link_phone_#{language}", announce_viber_account_conflict(language, name)} end
  def treat_msg("wait_for_no_more_offers", language, name, nb_offers) do {"link_phone_#{language}", announce_wait_for_no_more_active_offers(language, name, nb_offers)} end
  def treat_msg("technical problem", language) do {"link_phone_#{language}", announce_technical_error(language)} end
  def treat_msg("announce_accepted", user, announce, link) do {nil, tell_offer_online(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_moved", user, announce, link) do {nil, tell_offer_moved(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_refused", user, announce) do {nil, tell_offer_refused(user.language, user.nickname, announce.title, announce.cause)} end
  def treat_msg("quit_viber", db_user) do {nil, tell_viber_quitted(db_user.language, db_user.nickname)} end

  # --------- MESSAGES TO USER -------------------------------------------------------------------

  defp welcome_msg() do
    "Welcome to Pawchaungkaung !\nPlease choose your language :\n  -> Burmese (Zawgyi): type 1\n  -> Burmese (Unicode): type 2\n  -> English: type 3 "
  end

  defp welcome_back_msg(language, nickname) do
    case language do
      _ -> "(#{language})Welcome back to Pawchaungkaung #{nickname}!\nPlease choose your language :\n  -> Burmese (Zawgyi): type 1\n  -> Burmese (Unicode): type 2\n  -> English: type 3 "
    end
  end

  defp nothing_to_say_msg(language, nickname) do
    case language do
      _ -> "(#{language})Hi #{nickname} !\n #{say_something_neutral(language)}\n Please visit us on #{@website_url}"
    end
  end

  defp ask_phone_msg(language) do
    case language do
      _ -> "(#{language})Thanks ! Now we can speak. To identify you, please also type your mobile phone number."
    end
  end

  defp ask_again_phone_msg(language) do
    case language do
      _ -> "(#{language})Sorry to ask again. We need to identify you. Please also type your mobile phone number."
    end
  end

  defp inform_wrong_phone_number(language, nickname) do
    case language do
      _ -> "(#{language})Sorry #{nickname}, this is not a good phone number. To try again please type CHANGE."
    end
  end

  defp alert_before_phone_update(language, nickname) do
    case language do
      _ -> "(#{language})Ok #{nickname}, if you want to change your phone number please type it now.\nBe carefull all your announces will be moved to this new phone number !"
    end
  end

  defp confirm_user_created(language, nickname) do
    case language do
      _ -> "(#{language})Cool #{nickname}! Your phone number and viber account are now linked.\n Please visit us on #{@website_url}"
    end
  end

  defp tell_same_phone_number(language, nickname) do
    case language do
      _ -> "(#{language})You know what #{nickname}, your phone number was already linked to this viber account :)"
    end
  end

  defp confirm_new_phone_number_updated(language, nickname) do
    case language do
      _ -> "(#{language})Perfect #{nickname}, your viber account is now connected to this phone number.\n Please visit us on #{@website_url}"
    end
  end

  defp announce_phone_used(language) do
    case language do
      _ -> "(#{language})Sorry but this phone number is allready linked to another viber account. Please unlink it on #{@website_url_form} or contact us."
    end
  end

  defp announce_technical_error(language) do
    case language do
      _ -> "(#{language})Sorry we have a technical problem."
    end
  end

  defp announce_viber_account_conflict(language, nickname) do
    case language do
      _ -> "(#{language})Sorry #{nickname}, this phone number is used by another viber user. Please try again or contact us."
    end
  end

  defp announce_wait_for_no_more_active_offers(language, nickname, nb_offers) do
    case language do
      _ -> "(#{language})Sorry #{nickname}, this phone number has #{nb_offers} offers. You can wait for them to be expired or contact us."
    end
  end

  defp tell_offer_online(language, nickname, title, validity_date, link) do
    case language do
      _ -> "(#{language})Hi #{nickname}, your offer #{title} is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
    end
  end

  defp tell_offer_moved(language, nickname, title, validity_date, link) do
    case language do
      _ -> "(#{language})Hi #{nickname}, your offer #{title} has been moved to another category and is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
    end
  end

  defp tell_offer_refused(language, nickname, title, cause) do
    case language do
      _ -> "(#{language})Hi #{nickname}, we are sorry your offer #{title} was refused because #{cause}. Please create a new one on #{@website_url_form}"
    end
  end

  defp tell_viber_quitted(language, nickname) do
    case language do
      _ -> "(#{language})Hi #{nickname}, your Viber account has been unlinked. You can renew it at any time.\nSee you soon on #{@website_url}"
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
