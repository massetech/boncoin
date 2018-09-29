defmodule Boncoin.CustomModules.ViberBot do
  alias BoncoinWeb.LayoutView
  alias Boncoin.{Members, Contents}
  @website_url "https://www.pawchaungkaung.com"
  @website_url_form "https://www.pawchaungkaung.com/announces/new"

  # -------------------- DECISION  -------------------------------

  def call_bot_algorythm(%{scope: scope, user: user, announce: announce, viber: %{viber_id: viber_id, viber_name: viber_name, user_msg: user_msg}}) do
    cond do

      # We are welcoming the user
      scope == "welcome" ->
        case user do
          nil -> [treat_msg("welcome")]
          user -> [treat_msg("welcome_back", user)]
        end

      # We are waiting for a LANGUAGE
      scope == "language" ->
        language = String.slice(user_msg,0,1) |> convert_language()
        case user do
          nil -> # User unknown : we were waiting the user language input
            case language do
              nil -> [treat_msg("welcome")] # User didn't give his language, ask again
              _ -> [treat_msg("ask_phone", language)] # User gave his language
            end
          _ -> # User known : if different language then update
            if user.language != language do
              case Members.update_user(user, %{language: language}) do
                {:error, _user} -> [treat_msg("nothing_to_say", user)]
                {:ok, new_user} -> [treat_msg("nothing_to_say", new_user)]
              end
            end
        end

      # We are waiting for a NEW PHONE NUMBER to create the user
      user == nil && scope == "link_phone_mr" || scope == "link_phone_my" || scope == "link_phone_en" ->
        language = String.slice(scope, 11..12)
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
      scope == "offer_treated" ->
        case announce.status do
          "ONLINE" -> [treat_msg("announce_accepted", user, announce, build_announce_view_link(announce))]
          "REFUSED" -> [treat_msg("announce_refused", user, announce)]
        end

      # User wants to CHANGE LANGUAGE
      user != nil && user_msg == "*123#" -> [treat_msg("change_language", user)]

      # User wants to see his OFFERS LIST
      user != nil && user_msg == "*111#" ->
        offers = Contents.get_user_offers(user)
        case Kernel.length(offers) do
          0 -> [treat_msg("0_active_offer", user)]
          nb_offers ->
            msg = Enum.map(offers, fn offer -> build_detail_offer(user, offer) end)
            [treat_msg("nb_active_offers", user, nb_offers) | msg]
        end

      # User wants to UPDATE PHONE NUMBER
      user != nil && user_msg == "*888#" -> [treat_msg("change_phone", user)]

      # User confirms to UPDATE PHONE NUMBER
      user != nil && scope == "update_phone" ->
        case String.match?(user_msg, ~r/^([09]{1})([0-9]{10})$/) do
        false -> [treat_msg("wrong_phone_number", user)] # There is no phone number in the message : cancel the update
        true -> # There is a phone number in the message
          # IO.puts("Phone number updating from Viber")
          phone_number = user_msg
          other_user = Members.get_other_user_by_phone_number(phone_number)
          cond do
            user.phone_number == user_msg -> [treat_msg("same_phone_number", user)] # Same phone number then user old one
            other_user == nil -> # The phone number is not used yet : update the user phone number
              case Members.update_user(user, %{phone_number: phone_number}) do
                {:ok, user} -> [treat_msg("new_phone_updated", user)]
                _ -> [treat_msg("technical problem", user.language)]
              end
            true -> manage_phone_number_conflicts(user, other_user, phone_number, nil, nil, nil, "udate_phone") # The phone number is already used : check the rights
          end
        end

      # User is quitting Viber
      user != nil && user_msg == "*999#" ->
        answer = Members.remove_viber_id(user)
        case answer do
          {:ok, user} -> [treat_msg("quit_viber", user)]
          {:error, _msg} -> [treat_msg("cannot_quit_viber", user)]
        end

      # User asked for help
      user_msg == "0" -> [treat_msg("propose_help", user)]

      # Nothing to say (fallback)
      user != nil -> [treat_msg("nothing_to_say", user)]
      true -> [treat_msg("welcome")] # [treat_msg("repeat_phone", "mr")]

    end
  end

  def manage_phone_number_conflicts(user, other_user, phone_number, viber_id, user_name, language, scope) do
    # This loop can be used with or without user
    cond do
      other_user.viber_active == true -> [treat_msg("viber_conflict_contact_us", language, user_name)] # 2 Vibers for the same account : contact us
      # Rules removed to let a user link to Viber even if there is some announces
      # other_user.nb_announces > 0 -> treat_msg("wait_for_no_more_offers", language, user_name, other_user.nb_announces) # The new phone number has active offers : wait until there is no more
      # other_user.nb_announces == 0 &&
      scope == "link_phone" -> # The phone is not linked to viber and has no announce yet : use it to create new user
        other_user = Members.get_user!(other_user.id)
        case Members.update_user(other_user, %{viber_active: true, viber_id: viber_id, nickname: user_name, language: language}) do
          {:ok, user} -> [treat_msg("new_phone_updated", user)]
          _ -> [treat_msg("technical problem", language)]
        end
      # other_user.nb_announces == 0 &&
      scope == "udate_phone" -> # The new phone is not linked to viber and has no announce yet : update the user phone number
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

  defp convert_language(language_key) do
    case language_key do
      "1" -> "mr"
      "2" -> "my"
      "3" -> "en"
      _ -> nil
    end
  end

  # -------------------- MESSAGES   -------------------------------

  # User is not known
  def treat_msg("welcome") do %{scope: "language", msg: welcome_msg()} end
  def treat_msg("ask_phone", language) do %{scope: "link_phone_#{language}", msg: ask_phone_msg(language)} end
  def treat_msg("repeat_phone", language) do %{scope: "link_phone_#{language}", msg: ask_again_phone_msg(language)} end
  def treat_msg("technical problem", language) do %{scope: "link_phone_#{language}", msg: announce_technical_error(language)} end
  def treat_msg("viber_conflict_contact_us", language, user_name) do %{scope: nil, msg: announce_viber_account_conflict(language, user_name)} end

  # User is  known
  def treat_msg("new_user_created", user) do %{scope: nil, msg: confirm_user_created(user.language, user.nickname)} end
  def treat_msg("welcome_back", user) do %{scope: nil, msg: welcome_back_msg(user.language, user.nickname)} end
  def treat_msg("nothing_to_say", user) do %{scope: nil, msg: nothing_to_say_msg(user.language, user.nickname)} end
  def treat_msg("announce_accepted", user, announce, link) do %{scope: nil, msg: tell_offer_accepted(user.language, user.nickname, announce.title, LayoutView.format_date(announce.validity_date), link)} end
  def treat_msg("announce_refused", user, announce) do %{scope: nil, msg: tell_offer_refused(user.language, user.nickname, announce.title, announce.cause)} end
  def treat_msg("propose_help", user) do %{scope: "help", msg: inform_help(user.language, user.nickname)} end
  def treat_msg("change_language", user) do %{scope: "language", msg: change_language_msg(user.language, user.nickname)} end
  def treat_msg("change_phone", user) do %{scope: "update_phone", msg: alert_before_phone_update(user.language, user.nickname)} end
  def treat_msg("wrong_phone_number", user) do %{scope: nil, msg: inform_wrong_phone_number(user.language, user.nickname)} end
  def treat_msg("same_phone_number", user) do %{scope: nil, msg: tell_same_phone_number(user.language, user.nickname)} end
  def treat_msg("new_phone_updated", user) do %{scope: nil, msg: confirm_new_phone_number_updated(user.language, user.nickname)} end

  def treat_msg("quit_viber", user) do %{scope: nil, msg: tell_viber_quitted(user.language, user.nickname)} end
  def treat_msg("cannot_quit_viber", user) do %{scope: nil, msg: tell_viber_cannot_quit(user.language, user.nickname)} end
  def treat_msg("0_active_offer", user) do %{scope: nil, msg: tell_no_active_offer(user.language, user.nickname)} end
  def treat_msg("nb_active_offers", user, nb_offers) do %{scope: nil, msg: tell_nb_active_offers(user.language, user.nickname, nb_offers)} end
  def treat_msg("detail_active_offer", user, offer, link) do %{scope: nil, msg: detail_active_offers(user.language, offer.title, LayoutView.format_date(offer.validity_date), link)} end

  defp welcome_msg() do
    uni = "ပေါချောင်ကောင်းမှကြိုဆိုပါတယ်။ ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\nWelcome to Pawchaungkaung, please choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ [၁]\n  -> မြန်မာ(ယူနီကုတ်)အတွက် [၂]\n  -> For English send [3]"
  end

  defp change_language_msg(language, nickname) do
    uni = "ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပ"
    case language do
      "en" -> "Please choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ [၁]\n  -> မြန်မာ(ယူနီကုတ်)အတွက် [၂]\n  -> For English send [3]"
      "my" -> "#{uni}\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ [၁]\n  -> မြန်မာ(ယူနီကုတ်)အတွက် [၂]\n  -> For English send [3]"
      "mr" -> "#{Rabbit.uni2zg(uni)}\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ [၁]\n  -> မြန်မာ(ယူနီကုတ်)အတွက် [၂]\n  -> For English send [3]"
    end
  end

  # defp change_phone_msg(language, nickname) do
  #   case language do
  #     _ -> "Please choose your language\n  -> ျမမ္မားစာအတြက္ [1] ႏွိပ္ပါ \n  -> မြမ်မားစာအတွက် [2] နှိပ်ပါ \n  -> For English send [3]"
  #   end
  # end

  defp welcome_back_msg(language, nickname) do
    uni = "ပေါချောင်ကေင်းမှတစ်ဖန်ကြိုဆိုပါတယ် #{nickname} ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ။\n\n"
    case language do
      "en" -> "Welcome back to Pawchaungkaung #{nickname} !\n\nPlease visit us on #{@website_url}\n\nFor help please send [0]"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp nothing_to_say_msg(language, nickname) do
    uni = "မင်္ဂလာပါ #{nickname}။\n\nကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။\n\n"
    case language do
      "en" -> "Hi #{nickname} ! #{say_something_neutral(language)}\n\nPlease visit us on #{@website_url}\n\nFor help please send [0]"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp ask_phone_msg(language) do
    uni = "အခုစကားပြောလို့ရပါပြီ။ သင့်ကိုသတိပြုမိရန်သင်၏ဖုန်းနံပါတ်ကိုနှိပ်ပါ။"
    case language do
      "en" -> "Now we can speak! Please also type your mobile phone number."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp ask_again_phone_msg(language) do
    uni = "နောက်တစ်ကြိမ်မေးရတဲ့အတွက်အားနာပါတယ်။ Website မှသင့်ကိုသိရှိဖို့လိုအပ်ပါတယ်။ သင်၏ဖုန်းနံပါတ်ကိုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "Sorry but we need to identify you. Please type your mobile phone number."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp inform_wrong_phone_number(language, nickname) do
    uni = "စိတ်မကောင်းပါဘူး#{nickname}။ ဒီနံပါတ်မှားနေပါတယ်။ တဖန်ထပ်ကြိုးစားကြည့်ရန် [*888#] ဟုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "Sorry #{nickname}, this is not a good phone number. To try again please type [*888#]."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp alert_before_phone_update(language, nickname) do
    uni = "သင့်ကြော်ငြာအားလုံးကိုဖုန်းနံပါတ်အသစ်သို့ရွှေပြောင်းပေးမည်ဖြစ်ပါသည်။ သေကြာမှုရှိပြိဆိုလျင်သင့်ဖုန်းနံပါတ်ကသစ်ကိုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "All your offers will be moved to this new phone number. If you are sure please type your new phone number now.\n"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp confirm_user_created(language, nickname) do
    uni = "သင်၏ဖုန်းနံပါတ်နှင့်ဗိုင်ဘာနံပါတ်တို့သည် အဆက်အသွယ်ရပြီးပြီဖြစ်သည်။ \nကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။"
    case language do
      "en" -> "Your phone number and viber account are now linked.\nPlease visit us on #{@website_url}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_same_phone_number(language, nickname) do
    uni = "သင်သိလား သင့်ရဲ့ဖုန်းနံပါတ်က ပေါချောင်ကောင်းရဲ့ဗိုင်ဘာနဲ့ အဆက်အသွယ်ရပြီးသားဖြစ်နေပြီ။ :)"
    case language do
      "en" -> "You know what #{nickname}, your phone number was already linked to this viber account :)"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp confirm_new_phone_number_updated(language, nickname) do
    uni = "သင့်ဖုန်းနံပါတ်အသစ်သို့ပြေင်းပြိးဖြစ်သည် \nကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။"
    case language do
      "en" -> "Perfect #{nickname}, your phone number was updated.\n Please visit us on #{@website_url}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp announce_phone_used(language) do
    uni = "စိတ်မကောင်းပါဘူး ဒီနံဖုန်းပါတ်ကအခြားဗိုင်ဘာအကောင့်နဲ့ ချိတ်ဆက် ပြီးဖြစ်နေပါပြီ။ ကျေးဇူးပြု၍ ချိတ်ဆက်မှုကိုအရင်ဖြုတ်ပြစ်ရန် #{@website_url_form} သို့ဝင်ကြည့်ပါ။ (သို့) ပေါချောင်ကောင်းသို့ဆက်သွယ်ပါ။"
    case language do
      "en" -> "Sorry but this phone number is linked to another Viber user. Please unlink it first on #{@website_url_form} or contact us."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp announce_technical_error(language) do
    uni = "စိတ်မကောင်းပါဘူး website နည်းပညာပိုင်းဆိုင်ရာမှာ ပြဿနာရှိနေပါတယ်။"
    case language do
      "en" -> "Sorry we have a technical problem."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp announce_viber_account_conflict(language, nickname) do
    uni = "စိတ်မကောင်းပါဘူး #{nickname} ဒီဖုန်းနံပါတ်ကိုအခြားဗိုင်ဘာမှအသုံးပြုပြီးဖြစ်ပါတယ်။ ကျေးဇူးပြု၍ နောက်ထပ်တစ်ကြိမ်ပြန် ကြိုးစားကြည့်ပါ။ (သို့) ပေါချောင်ကောင်းသို့ဆက်သွယ်ပါ။"
    case language do
      "en" -> "Sorry #{nickname}, this phone number is linked to another Viber user. Please unlink it first on #{@website_url_form} or contact us."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp inform_help(language, nickname) do
    uni = "ကျွန်တော်/မ တို့သည် #{nickname} ကိုကူညီရန်အသင့်ပါ၊ \n\nဘာသာစကားပြောင်းရန် [*123#]\nသင့်ကြော်ငြာကိုကြည့်ရန် [*111#]\nဖုန်းနံပါတ်ပြောင်းရန် [*888#]\nViber မှထွက်ရန် [*999#]"
    case language do
      "en" -> "We are happy to help #{nickname},\n\nchange language [*123#]\nsee your offers [*111#]\nchange phone number [*888#]\nquit Viber [*999#]"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_offer_accepted(language, nickname, title, validity_date, link) do
    uni = "မင်္ဂလာပါ #{nickname} သင်၏ရောင်းရန်ပစ္စည်း သည်ကြော်ငြာတင်လိုက်ပြီဖြစ်ပါသည်။ ၎င်းကို #{validity_date} အထိ (၁)လအကြာ ကြော်ငြာတင်ထားမည် ဖြစ်သည်။ သင်၏ကြော်ငြာကိုသင့်အလိုကျစီမံနိုင်ရန် #{@website_url}#{link} သို့ဝင်ပါ။"
    case language do
      "en" -> "Hi #{nickname}, your offer #{title} is now published !\nIt will be online for 1 month until #{validity_date}.\nYou can manage your offer on #{@website_url}#{link}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_offer_refused(language, nickname, title, cause) do
    uni = "မင်္ဂလာပါ #{nickname}၊ စိတ်မကောင်းပါဘူး သင့်ရဲ့ #{title} ကြော်ငြာဟာ #{cause} ကြောင့်ငြင်းပယ်ခြင်းခံရပါတယ်။ ကျေးဇူးပြု၍ #{@website_url_form} တွင်အသစ်တစ်ဖန်ပြန်လုပ်ပါ။"
    case language do
      "en" -> "Hi #{nickname}, we are sorry but your offer #{title} was refused because #{cause}. \nPlease create a new one on #{@website_url_form}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_viber_quitted(language, nickname) do
    uni = "မင်္ဂလာပါ #{nickname}၊ သင့်ရဲ့ဗိုင်ဘာချိတ်ဆက်မှုကိုဖြုတ်ပြစ်ပြီးဖြစ်ပါပြီ။ မကြာခင်မှာ #{@website_url} တွင်ပြန်ဆုံကြမယ်နော်။"
    case language do
      "en" -> "Your Viber account has been unlinked.\nHope to see you soon on #{@website_url}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_viber_cannot_quit(language, nickname) do
    uni = "စိတ်မကောင်းပါဘူး#{nickname}၊ သင်ရဲ Viber ကိုဖြုတ်ဂျမရပါ။ ကျေးဇူးပြု၍သင်၏ကျွန်တော်/မတို့ကိုဆက်သွယ်ပါ။"
    case language do
      "en" -> "Sorry #{nickname} but we cannot unlink your Viber. Please contact us."
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_no_active_offer(language, nickname) do
    uni = "သင့်တွင်ကြော်ငြာမရှိသေးပါ။ ကျေးဇူးပြု၍သင်၏ပထမကြော်ငြာကိုတင်လိုက်ပါ။"
    case language do
      "en" -> "You don't have any offer yet #{nickname}. Please create your first offer on #{@website_url_form}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_nb_active_offers(language, nickname, nb_offers) do
    uni = "Ok #{nickname}၊ သင့်တွင်ကြော်ငြာ #{nb_offers} ခုရှိပါသည်"
    case language do
      "en" -> "Ok #{nickname}, you have #{nb_offers} active offers :"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp detail_active_offers(language, title, validity_date, link) do
    uni = "#{title}\n#{validity_date} အထိ\n#{@website_url}#{link} တွင်လုပ်ဆောင်ရန်"
    case language do
      "en" -> "#{title}\nActive until #{validity_date}.\nManage it on #{@website_url}#{link}"
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp say_something_neutral(language) do
    case Enum.random([1, 2, 3, 4, 5]) do
      1 ->
        # Say nothing
        case language do
          _ -> ""
        end
      2 ->
        uni = "အဆင်ပြေမယ်လို့မျှော်လင့်ပါတယ်။"
        case language do
          "en" -> "Hope you are fine !"
          "my" -> uni
          "mr" -> Rabbit.uni2zg(uni)
        end
      3 ->
        uni = "ဘာတွေထူးလဲ။"
        case language do
          "en" -> "What's up ?"
          "my" -> uni
          "mr" -> Rabbit.uni2zg(uni)
        end
      4 ->
        uni = "ဘာအလိုရှိပါသလဲ။"
        case language do
          "en" -> "Searching something ?"
          "my" -> uni
          "mr" -> Rabbit.uni2zg(uni)
        end
      5 ->
        uni = "တစ်ခုခုရောင်းချင်ပါသလား။"
        case language do
          "en" -> "Selling something ?"
          "my" -> uni
          "mr" -> Rabbit.uni2zg(uni)
        end
    end
  end

end
