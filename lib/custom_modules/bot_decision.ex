defmodule Boncoin.CustomModules.BotDecisions do
  alias Boncoin.{Members, Contents}
  alias Boncoin.Members.User
  alias BoncoinWeb.LayoutView
  @website_url Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:website_url]

  # -------------------- DECISION  -------------------------------

  def call_bot_algorythm(%{user: user, conversation: conversation, announce: announce, user_msg: user_msg} = bot_params) do
    # IO.puts("--- bot params---")
    # IO.inspect(bot_params)

    cond do

      # We are welcoming the user (no conversation yet)
      conversation.scope == nil ->
        case user do
          nil -> %{scope: "language", language: nil, messages: [welcome_msg()]}
          user -> %{scope: "no_scope", language: user.language, messages: [welcome_back_msg(user)]}
        end

      # We are waiting for a LANGUAGE
      conversation.scope == "language" ->
        language = String.slice(user_msg,0,1) |> convert_language()
        case user do
          nil -> # User unknown : we were waiting the user language input
            case language do
              nil -> %{scope: "language", language: nil, messages: [welcome_msg()]} # User didn't give his language, ask again
              language -> %{scope: "link_phone_1", language: language, messages: [ask_phone_msg(language)]}
            end
          _ -> # User known : if different language then update
            if user.language != language && language != nil do
              case Members.udpate_and_track_user(user, %{language: language}) do
                {:ok, new_user} -> %{scope: "no_scope", language: language, messages: [nothing_to_say_msg(new_user)]}
                {:error, _} -> %{scope: "no_scope", language: user.language, messages: [nothing_to_say_msg(user)]}
              end
            else
              %{scope: "no_scope", language: user.language, messages: [nothing_to_say_msg(user)]}
            end
        end

      # We are waiting for a PHONE NUMBER for first or second time
      user == nil && String.contains?(conversation.scope, "link_phone") ->
        language = conversation.language
        phone_number = user_msg
        # len = String.length(conversation.scope)
        case User.check_myanmar_phone_number(phone_number) do
          false ->
            case String.contains?(conversation.scope, "link_phone_2") do
              false -> # There is no phone number in the message : ask again for it
                %{scope: "link_phone_2", language: language, messages: [ask_again_phone_msg(language)]}
              true -> # There is no phone number in the message for the 2nd time : return to language asking
                %{scope: "language", language: nil, messages: [welcome_msg()]}
            end
          true -> # There is a phone number in the message
            other_user = Members.get_active_user_by_phone_number(phone_number)
            case other_user do
              nil -> # The phone number is not used yet : create the user with this phone number
                user_params = %{active: true, phone_number: phone_number, bot_active: true, bot_provider: conversation.bot_provider, bot_id: conversation.psid, nickname: conversation.nickname, language: language}
                case Members.create_and_track_user(user_params) do
                  {:ok, new_user} -> %{scope: "no_scope", language: language, messages: [confirm_user_created(new_user)]}
                  {:error, changeset} ->
                    IO.inspect(changeset)
                    %{scope: "no_scope", language: language, messages: [announce_technical_error(language)]}
                end
              other_user -> # The phone number is already used
                case conversation.psid == other_user.bot_id && conversation.bot_provider == other_user.bot_provider do
                  true -> # other_user is the same user comming back with the same bot
                    case Members.udpate_and_track_user(other_user, %{bot_active: true}) do
                      {:ok, user} -> %{scope: "no_scope", language: user.language, messages: [confirm_old_phone_number_retrieved(user)]}
                      {:error, changeset} ->
                        IO.inspect(changeset)
                        %{scope: "no_scope", language: language, messages: [announce_technical_error(language)]}
                    end
                  false -> # There is a conflict on the phone number
                    case manage_phone_conflict(user, other_user) do
                      false -> # User creation refused for this phone number
                        %{scope: "link_phone_1", language: language, messages: [announce_bot_conflict(conversation.language, conversation.nickname)]}
                      true -> # User creation accepted for this phone number
                        user_params = %{active: true, phone_number: phone_number, bot_active: true, bot_provider: conversation.bot_provider, bot_id: conversation.psid, nickname: conversation.nickname, language: language}
                        case Members.create_and_track_user(user_params) do
                          {:ok, new_user} -> %{scope: "no_scope", language: language, messages: [confirm_user_created(new_user)]}
                          {:error, changeset} ->
                            IO.inspect(changeset)
                            %{scope: "no_scope", language: language, messages: [announce_technical_error(user_params.language)]}
                        end
                    end
                end
            end
        end

      # We send a NOTIFICATION to user after treating the offer
      user != nil && conversation.scope == "offer_treated" ->
        language = user.language
        case announce.status do
          "ONLINE" -> %{scope: "offer_msg", language: language, messages: [tell_offer_accepted(user, announce)]}
          "REFUSED" -> %{scope: "offer_msg", language: language, messages: [tell_offer_refused(user, announce, user_msg)]}
        end

      # We send a NOTIFICATION to user after removing his offer
      user != nil && conversation.scope == "offer_closed" ->
        language = user.language
        %{scope: "offer_msg", language: language, messages: [tell_offer_closed(user, announce, user_msg)]}

      # User wants to CHANGE LANGUAGE
      user != nil && user.bot_active == true && user_msg == "*123#" ->
        language = user.language
        %{scope: "language", language: language, messages: [change_language_msg()]}

      # User wants to see his OFFERS LIST
      user != nil && user.bot_active == true && user_msg == "*111#" ->
        language = user.language
        offers = Contents.get_user_online_offers(user)
        case Kernel.length(offers) do
          0 -> %{scope: "no_scope", language: language, messages: [tell_no_active_offer(user)]}
          nb_offers ->
            msg = Enum.map(offers, fn offer -> detail_active_offers(user, offer) end)
            %{scope: "no_scope", language: language, messages: [tell_nb_active_offers(user, nb_offers) | msg]}
        end

      # User wants to UPDATE PHONE NUMBER
      user != nil && user.bot_active == true && user_msg == "*888#" ->
        language = user.language
        %{scope: "update_phone", language: language, messages: [alert_before_phone_update(user)]}

      # User confirms to UPDATE PHONE NUMBER
      user != nil && user.bot_active == true && conversation.scope == "update_phone" ->
        language = user.language
        phone_number = user_msg
        case User.check_myanmar_phone_number(phone_number) do
          false -> %{scope: "no_scope", language: language, messages: [inform_wrong_phone_number(user)]} # There is no phone number in the message : cancel the update
          true -> # There is a phone number in the message
            other_user = Members.get_active_user_by_phone_number(phone_number)
            cond do
              other_user == nil ->  # The phone number is not used yet
                case Members.udpate_and_track_user(user, %{phone_number: phone_number}) do
                  {:ok, user} -> %{scope: "no_scope", language: language, messages: [confirm_new_phone_number_updated(user)]}
                  {:error, changeset} ->
                    IO.inspect(changeset)
                    %{scope: "no_scope", language: language, messages: [announce_technical_error(language)]}
                end
              user.phone_number == user_msg -> # Same phone number then user old one
                %{scope: "no_scope", language: language, messages: [tell_same_phone_number(user)]}
              true -> # The phone number is already used : conflict
                case user.bot_id == other_user.bot_id && user.bot_provider == other_user.bot_provider do
                  true -> # other_user is the same user comming back with the same bot
                    case Members.udpate_and_track_user(other_user, %{phone_number: phone_number, bot_active: true}) do
                      {:ok, user} -> %{scope: "no_scope", language: language, messages: [confirm_old_phone_number_retrieved(user)]}
                      {:error, changeset} ->
                        IO.inspect(changeset)
                        %{scope: "no_scope", language: language, messages: [announce_technical_error(language)]}
                    end
                  false -> # There is a conflict on the phone number
                    case manage_phone_conflict(user, other_user) do
                      false -> # User change phone number refused
                        %{scope: "no_scope", language: language, messages: [announce_bot_conflict(language, user.nickname)]}
                      true -> # User change phone number accepted
                        case Members.udpate_and_track_user(user, %{phone_number: phone_number}) do
                          {:ok, new_user} -> %{scope: "no_scope", language: language, messages: [confirm_new_phone_number_updated(new_user)]}
                          {:error, _changeset} -> %{scope: "no_scope", language: language, messages: [announce_technical_error(language)]}
                        end
                    end
                end
            end
        end

      # User wants to QUIT BOT
      user != nil && user.bot_active == true && user_msg == "*999#" ->
        language = user.language
        answer = Members.permission_to_quit_bot(user)
        case answer do
          {:ok, _msg} -> %{scope: "quit_bot", language: language, messages: [alert_before_quit_bot(user)]}
          {:not_allowed, nb_offers} -> %{scope: "no_scope", language: language, messages: [tell_not_allowed_to_quit_bot(user, nb_offers)]}
        end

      # User confirms to QUIT BOT
      user != nil && user.bot_active == true && conversation.scope == "quit_bot" && user_msg == "1" ->
        language = user.language
        answer = Members.remove_bot(user)
        case answer do
          {:ok, _user} -> %{scope: "closed", language: language, messages: [tell_bot_quitted(user)]}
          {:not_allowed, nb_offers} -> %{scope: "no_scope", language: language, messages: [tell_not_allowed_to_quit_bot(user, nb_offers)]}
          {:error, _msg} -> %{scope: "no_scope", language: language, messages: [tell_bot_cannot_quit(user)]}
        end

      # User asked for help
      user != nil && user.bot_active == true && user.bot_active == true && user_msg == "0" ->
        language = user.language
        %{scope: "no_scope", language: language, messages: [inform_help(user)]}

      # Nothing to say (fallbacks)
      user != nil && user.bot_active ->
        language = user.language
        %{scope: "no_scope", language: language, messages: [nothing_to_say_msg(user)]}
      true ->
        %{scope: "language", language: nil, messages: [welcome_msg()]}

    end
  end

  defp manage_phone_conflict(user, other_user) do
    cond do
      other_user.bot_active == true -> false # Other user bot active = forbidden
      Contents.get_user_active_offers(other_user) != [] -> false # Other user has active offers = forbidden
      true ->
        Members.udpate_and_track_user(other_user, %{active: false}) # We cancel other user forever (history)
        true # We accept the usage of this phone number
    end
  end

  # Build link for the user
  # defp build_detail_offer(user, offer) do
  #   treat_msg("detail_active_offer", user, offer, build_announce_view_link(offer))
  # end

  defp convert_language(language_key) do
    case language_key do
      "1" -> "dz"
      "2" -> "my"
      "3" -> "en"
      _ -> nil
    end
  end

  defp offer_form_link(phone_number) do
    "#{@website_url}/offer/new/#{phone_number}"
  end

  # defp offer_view_link(safe_link) do
  #   "#{@website_url}/user/offer/#{safe_link}"
  # end

  def offer_view_link(offer_id) do
    url = "#{@website_url}/user/offer/#{offer_id}"
      |> Cipher.sign_url()
  end

  # -------------------- MESSAGES   -------------------------------

  defp welcome_msg() do
    uni = "ပေါချောင်ကောင်းမှကြိုဆိုပါတယ်။ ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\n\nWelcome to Pawchaungkaung, please choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ 1\n  -> မြန်မာ(ယူနီကုတ်)အတွက် 2\n  -> For English send 3"
  end

  def change_language_msg() do
    uni = "ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\n\nPlease choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ 1\n  -> မြန်မာ(ယူနီကုတ်)အတွက် 2\n  -> For English send 3"
  end

  defp welcome_back_msg(user) do
    uni = "ပေါချောင်ကေင်းမှတစ်ဖန်ကြိုဆိုပါတယ် #{user.nickname}။\n\nကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။\n\nအကူအညီရယူရန် 0 ဟုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Welcome back to Pawchaungkaung #{user.nickname} !\n\nPlease visit us on #{@website_url}\n\nFor help please send 0"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp nothing_to_say_msg(user) do
    uni = "မင်္ဂလာပါ #{user.nickname}။\n\nကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။\n\nအကူအညီရယူရန် 0 ဟုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Hi #{user.nickname} ! #{say_something_neutral(user.language)}\n\nPlease visit us on #{@website_url}\n\nFor help please send 0"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp ask_phone_msg(language) do
    uni = "အခုစကားပြောလို့ရပါပြီ။ ကျေးဇူးပြုပြီးသင်၏ဖုန်းနံပါတ်ကိုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "Now we can speak! Please also type your mobile phone number."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp ask_again_phone_msg(language) do
    uni = "နောက်တစ်ကြိမ်မေးရတဲ့အတွက်အားနာပါတယ်။ Website မှသင့်ကိုသိရှိဖို့လိုအပ်ပါတယ်။ သင်၏ဖုန်းနံပါတ်ကိုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "Sorry but we need to identify you. Please type your mobile phone number."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp inform_wrong_phone_number(user) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}။ ဒီနံပါတ်မှားနေပါတယ်။ တဖန်ထပ်ကြိုးစားကြည့်ရန် *888# ဟုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Sorry #{user.nickname}, this is not a good phone number. To try again please type *888#"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp alert_before_phone_update(user) do
    uni = "သင့်ကြော်ငြာအားလုံးကိုဖုန်းနံပါတ်အသစ်သို့ရွှေပြောင်းပေးမည်ဖြစ်ပါသည်။ သေချာမှုရှိပြိဆိုလျင်သင့်ဖုန်းနံပါတ်အသစ်ကိုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "All your offers will be moved to this new phone number. If you are sure please type your new phone number now."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp confirm_user_created(user) do
    uni = "သင်၏ဖုန်းနံပါတ်နှင့် #{String.capitalize(user.bot_provider)} နံပါတ်တို့သည် အဆက်အသွယ်ရပြီးပြီဖြစ်သည်။ \nကျေးဇူးပြု၍ #{offer_form_link(user.phone_number)} သို့ဝင်ကြည့်ပါ။"
    case user.language do
      "en" -> "Your phone number and #{String.capitalize(user.bot_provider)} account are now linked.\nPlease visit us on #{offer_form_link(user.phone_number)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_same_phone_number(user) do
    uni = "သင်သိလား သင့်ရဲ့ဖုန်းနံပါတ်က ပေါချောင်ကောင်းရဲ့ #{String.capitalize(user.bot_provider)} နဲ့ အဆက်အသွယ်ရနေပါပြီ။ :)"
    case user.language do
      "en" -> "You know what #{user.nickname}, your phone number was already linked to this #{String.capitalize(user.bot_provider)} account :)"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp confirm_new_phone_number_updated(user) do
    uni = "အဆင်ပြေပါပြီ #{user.nickname},  သင့်ဖုန်းနံပါတ်အသစ်ပြန်ပြင်ပြိးဖြစ်သည် \n ကျေးဇူးပြု၍ #{@website_url} သို့ဝင်ကြည့်ပါ။"
    case user.language do
      "en" -> "Perfect #{user.nickname}, your phone number was updated.\n Please visit us on #{@website_url}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp confirm_old_phone_number_retrieved(user) do
    uni = "အဆင်ပြေပါပြီ #{user.nickname}, သင့်ရဲ့ ဖုန်းနံပါတ်ကိုပြန်ရပါပြီ \n ကျေးဇူးပြု၍ #{user.nickname}, သို့ဝင်ကြည့်ပါ။"
    case user.language do
      "en" -> "Perfect #{user.nickname}, you get back your phone number.\n Please visit us on #{@website_url}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp announce_technical_error(language) do
    uni = "စိတ်မကောင်းပါဘူး website နည်းပညာပိုင်းဆိုင်ရာမှာ ပြဿနာရှိနေပါတယ်။"
    case language do
      "en" -> "Sorry we have a technical problem."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp announce_bot_conflict(language, nickname) do
    uni = "စိတ်မကောင်းပါဘူး #{nickname} ဒီဖုန်းနံပါတ်ကိုအခြားသူမှအသုံးပြုပြီးဖြစ်ပါတယ်။ ကျေးဇူးပြု၍ နောက်ထပ်တစ်ကြိမ်ပြန်၍ ကြိုးစားကြည့်ပါ။ (သို့) ပေါချောင်ကောင်းသို့ဆက်သွယ်ပါ။"
    case language do
      "en" -> "Sorry #{nickname}, this phone number is used by another user. Please unlink it first or contact us."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp inform_help(user) do
      uni = "ကျွန်တော်/မ တို့သည် #{user.nickname} ကိုကူညီရန်အသင့်ပါ၊ \n\nဘာသာစကားပြောင်းရန် *123#\nသင့်ကြော်ငြာကိုကြည့်ရန် *111#\nဖုန်းနံပါတ်ပြောင်းရန် *888#\n#{String.capitalize(user.bot_provider)} မှထွက်ရန် *999#"
    case user.language do
      "en" -> "We are happy to help #{user.nickname},\n\nchange language *123#\nsee your offers *111#\nchange phone number *888#\nquit #{String.capitalize(user.bot_provider)} *999#"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_offer_accepted(user, offer) do
    uni = "မင်္ဂလာပါ #{user.nickname} သင်၏ရောင်းရန်ပစ္စည်းကြော်ငြာကို တင်လိုက်ပြီဖြစ်ပါသည်။ ၎င်းကို #{LayoutView.format_date(offer.validity_date)} အထိ (၁)လအကြာ ကြော်ငြာတင်ထားမည် ဖြစ်သည်။ သင်၏ကြော်ငြာကိုသင့်အလိုကျစီမံနိုင်ရန် #{offer_view_link(offer.id)} သို့ဝင်ပါ။"
    case user.language do
      "en" -> "Hi #{user.nickname}, your offer #{offer.title} is now published !\nIt will be online for 1 month until #{LayoutView.format_date(offer.validity_date)}.\nYou can manage your offer on #{offer_view_link(offer.id)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_offer_refused(user, offer, cause) do
    uni = "မင်္ဂလာပါ #{user.nickname}၊ စိတ်မကောင်းပါဘူး သင့်ရဲ့ #{offer.title} ကြော်ငြာဟာ #{cause} ကြောင့်ငြင်းပယ်ခြင်းခံရပါတယ်။ \nကျေးဇူးပြု၍ #{offer_form_link(user.phone_number)} တွင်အသစ်တစ်ဖန်ပြန်လုပ်ပါ။"
    case user.language do
      "en" -> "Hi #{user.nickname}, we are sorry but your offer #{offer.title} was refused because #{cause}. \nPlease create a new one on #{offer_form_link(user.phone_number)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_offer_closed(user, offer, cause) do
    uni = "မင်္ဂလာပါ #{user.nickname}၊ သင့်ရဲ့ #{offer.title} ကြော်ငြာကို#{cause}ပိတ်လိုက်ပါပြီ။ \nကျေးဇူးပြု၍ #{offer_form_link(user.phone_number)} တွင်အသစ်တစ်ဖန်ပြန်လုပ်ပါ။"
    case user.language do
      "en" -> "Hi #{user.nickname}, your offer #{offer.title} has been closed #{cause}. \nPlease create a new one on #{offer_form_link(user.phone_number)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp alert_before_quit_bot(user) do
    uni = "သင့်ရဲ့ #{String.capitalize(user.bot_provider)} ချိတ်ဆက်မှုကိုပြန်လည်ဖြုတ်ချင်သည်မှာသေခြာပြီလား။ သေခြာလျှင် (၁)ဟုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Are you sure you want to remove #{String.capitalize(user.bot_provider)} link ?. If you are sure please type 1"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_bot_quitted(user) do
    uni = "မင်္ဂလာပါ #{user.nickname}၊ သင့်ရဲ့ #{String.capitalize(user.bot_provider)} ချိတ်ဆက်မှုကိုဖြုတ်ပြီးပါပြီ။ မကြာခင်မှာ #{@website_url} တွင်ပြန်ဆုံကြမယ်နော်။"
    case user.language do
      "en" -> "Your #{String.capitalize(user.bot_provider)} account has been unlinked.\nHope to see you soon on #{@website_url}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_not_allowed_to_quit_bot(user, nb_offers) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}, သင့်ထံမှာ ကြော်ငြာ #{nb_offers} ရှိနေသေးသောကြောင့် သင့်ရဲ့ #{String.capitalize(user.bot_provider)} ကိုအချိတ်အဆက်ဖြုတ်၍မရပါ \n\n အကူအညီရယူရန် ဟုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Sorry #{user.nickname}, we cannot unlink your #{String.capitalize(user.bot_provider)} account because you still have #{nb_offers} offers. \n\nFor help please send 0"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_bot_cannot_quit(user) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}၊ သင်ရဲ့ #{String.capitalize(user.bot_provider)} ကိုဖြုတ်၍မရပါ။ ကျေးဇူးပြု၍ ကျွန်တော်/မတို့ကိုဆက်သွယ်ပါ။"
    case user.language do
      "en" -> "Sorry #{user.nickname} but we cannot unlink your #{String.capitalize(user.bot_provider)} account. Please contact us."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_no_active_offer(user) do
    uni = "သင့်မှာမည်သည့်ကြော်ငြာမျှမရှိသေးပါ။ ကျေးဇူးပြု၍သင်၏ပထမဆုံးကြော်ငြာကို #{offer_form_link(user.phone_number)} တွင်တင်လိုက်ပါ။"
    case user.language do
      "en" -> "You don't have any offer yet. Please create your first offer on #{offer_form_link(user.phone_number)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp tell_nb_active_offers(user, nb_offers) do
    uni = "Ok #{user.nickname}၊ သင့်တွင်လက်ရှိကြော်ငြာ #{nb_offers} ခုရှိပါသည်"
    case user.language do
      "en" -> "Ok #{user.nickname}, you have #{nb_offers} active offers :"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  defp detail_active_offers(user, offer) do
    uni = "#{offer.title}\n#{LayoutView.format_date(offer.validity_date)} အထိကြော်ငြာတင်ထားမည်။ \n#{offer_view_link(offer.id)} တွင်လုပ်ဆောင်ရန်"
    case user.language do
      "en" -> "#{offer.title}\nActive until #{LayoutView.format_date(offer.validity_date)}.\nManage it on #{offer_view_link(offer.id)}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
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
          "dz" -> Rabbit.uni2zg(uni)
        end
      3 ->
        uni = "ဘာတွေထူးလဲ။"
        case language do
          "en" -> "What's up ?"
          "my" -> uni
          "dz" -> Rabbit.uni2zg(uni)
        end
      4 ->
        uni = "ဘာအလိုရှိပါသလဲ။"
        case language do
          "en" -> "Searching something ?"
          "my" -> uni
          "dz" -> Rabbit.uni2zg(uni)
        end
      5 ->
        uni = "တစ်ခုခုရောင်းချင်ပါသလား။"
        case language do
          "en" -> "Selling something ?"
          "my" -> uni
          "dz" -> Rabbit.uni2zg(uni)
        end
    end
  end

end
