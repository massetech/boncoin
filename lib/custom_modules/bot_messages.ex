defmodule Boncoin.CustomModules.BotMessages do
  alias Boncoin.Members
  alias BoncoinWeb.LayoutView
  @website_url "https://www.pawchaungkaung.com"
  @website_url_form "https://www.pawchaungkaung.com/announces/new"

  # User is not necessarely known
  def treat_msg("welcome") do %{tracking_data: "language", msg: welcome_msg()} end
  def treat_msg("ask_phone", language) do %{tracking_data: "link_phone_#{language}", msg: ask_phone_msg(language)} end
  def treat_msg("repeat_phone", language) do %{tracking_data: "link_phone_#{language}", msg: ask_again_phone_msg(language)} end
  def treat_msg("technical problem", language) do %{tracking_data: "link_phone_#{language}", msg: announce_technical_error(language)} end
  def treat_msg("viber_conflict_contact_us", language, user_name) do %{tracking_data: nil, msg: announce_viber_account_conflict(language, user_name)} end

  # User is always known
  def treat_msg("welcome_back", user) do %{tracking_data: nil, msg: welcome_back_msg(user.language, user.nickname)} end
  def treat_msg("nothing_to_say", user) do %{tracking_data: nil, msg: nothing_to_say_msg(user.language, user.nickname)} end
  def treat_msg("wrong_phone_number", user) do %{tracking_data: nil, msg: inform_wrong_phone_number(user.language, user.nickname)} end
  def treat_msg("new_user_created", user) do %{tracking_data: nil, msg: confirm_user_created(user.language, user.nickname)} end
  def treat_msg("same_phone_number", user) do %{tracking_data: nil, msg: tell_same_phone_number(user.language, user.nickname)} end
  def treat_msg("propose_phone_update", user) do %{tracking_data: "update_phone", msg: alert_before_phone_update(user.language, user.nickname)} end
  def treat_msg("new_phone_updated", user) do %{tracking_data: nil, msg: confirm_new_phone_number_updated(user.language, user.nickname)} end
  # def treat_msg(tracking_data: "wait_for_no_more_offers", language, name, nb_offers) do %{"link_phone_#{language}", msg: announce_wait_for_no_more_active_offers(language, name, nb_offers)} end
  def treat_msg("give_help", user) do %{tracking_data: nil, msg: inform_help(user.language, user.nickname)} end
  def treat_msg("announce_accepted", user, announce, link) do %{tracking_data: nil, msg: tell_offer_online(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_moved", user, announce, link) do %{tracking_data: nil, msg: tell_offer_moved(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_refused", user, announce) do %{tracking_data: nil, msg: tell_offer_refused(user.language, user.nickname, announce.title, announce.cause)} end
  def treat_msg("quit_viber", user) do %{tracking_data: nil, msg: tell_viber_quitted(user.language, user.nickname)} end
  def treat_msg("cannot_quit_viber", user) do %{tracking_data: nil, msg: tell_viber_cannot_quit(user.language, user.nickname)} end
  def treat_msg("0_active_offer", user) do %{tracking_data: nil, msg: tell_no_active_offer(user.language, user.nickname)} end
  def treat_msg("nb_active_offers", user, nb_offers) do %{tracking_data: nil, msg: tell_nb_active_offers(user.language, user.nickname, nb_offers)} end
  def treat_msg("detail_active_offer", user, offer, link) do %{tracking_data: nil, msg: detail_active_offers(user.language, offer.title, LayoutView.format_date(offer.validity_date), link)} end
  # --------- MESSAGES TO USER -------------------------------------------------------------------

  defp welcome_msg() do
    "Welcome to Pawchaungkaung !\nWhat is your language ?\n  -> ျမမ္မားစာအတြက္ [1] ႏွိပ္ပါ \n  -> မြမ်မားစာအတွက် [2] နှိပ်ပါ \n  -> For English press 3"
  end

  defp welcome_back_msg(language, nickname) do
    case language do
      _ -> "Welcome back to Pawchaungkaung #{nickname} !\nPlease visit us on #{@website_url}"
    end
  end

  defp nothing_to_say_msg(language, nickname) do
    case language do
      _ -> "Hi #{nickname} !\n #{say_something_neutral(language)}\n Please visit us on #{@website_url}"
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
      _ -> "Sorry #{nickname}, this is not a good phone number. To try again please type [000#]."
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
      _ -> "Hey #{nickname},\ntype [0] to change your language,\ntype [123#] to see your active offers,\ntype [000#] to change your phone number,\n-> type [999#] to unlink Viber."
    end
  end

  # defp announce_wait_for_no_more_active_offers(language, nickname, nb_offers) do
  #   case language do
  #     _ -> "Sorry #{nickname}, this phone number has #{nb_offers} offers. You can wait for them to be expired or contact us."
  #   end
  # end

  defp tell_offer_online(language, nickname, title, validity_date, link) do
    case language do
      _ -> "Hi #{nickname}, your offer #{title} is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
    end
  end

  defp tell_offer_moved(language, nickname, title, validity_date, link) do
    case language do
      # _ -> "Hi #{nickname}, your offer #{title} has been moved to another category and is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
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
