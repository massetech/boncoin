defmodule Boncoin.CustomModules.BotDecisions do
  alias Boncoin.{Members, Contents}
  alias Boncoin.Members.User
  alias BoncoinWeb.LayoutView

  # -------------------- BOT ALGORYTHM  -------------------------------

  def call_bot_algorythm(%{user: user, conversation: conversation, announce: announce, user_msg: user_msg} = bot_params) do
    # IO.puts("--- bot params---")
    # IO.inspect(bot_params)

    cond do
      #---------------------- USER REGISTRATION -------------------------------------

      # We are welcoming a new visitor
      user == nil && conversation.scope == "welcome" ->
        if conversation.bot_provider == "viber" do # Viber opening conversation doesn't let us display quick_replies : ask user to type
          %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg_full(), offers: [], quick_replies: [], buttons: []}}
        else
          %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}
        end
      # We are waiting for a visitor LANGUAGE
      user == nil && conversation.scope == "language" ->
        language = String.slice(user_msg,0,1) |> convert_language()
        case language do
          nil ->
            %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}
          language ->
            %{conversation: %{scope: "visit_purpose", language: language, nb_errors: 0}, messages: %{message: ask_visit_purpose_msg(language), offers: [], quick_replies: [%{title: tell_registration(language), link: "1"}, %{title: tell_no_registration(language), link: "0"}], buttons: []}}
        end

      # We are welcoming a returning visitor (he has a language allready)
      user == nil && conversation.scope == "visitor" ->
        language = conversation.language
        case conversation.nb_errors do
          0 -> # No error : ask the visit purpose
            %{conversation: %{scope: "visit_purpose", nb_errors: 1}, messages: %{message: ask_visit_purpose_msg(language), offers: [], quick_replies: [%{title: tell_registration(language), link: "1"}, %{title: tell_no_registration(language), link: "0"}], buttons: []}}  # We let the visitor return one time only
          1 -> # Errors : fallback to language asking
            %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}
        end

      # We are waiting the visitor's VISIT PURPOSE
      user == nil && conversation.scope == "visit_purpose" ->
        language = conversation.language
        case user_msg do
          "1" -> # Visitor wants to register
            %{conversation: %{scope: "link_phone", nb_errors: 0}, messages: %{message: ask_phone_msg(language), offers: [], quick_replies: [], buttons: []}}
          _ -> # Visitor doesn't want to register
            %{conversation: %{scope: "visitor", nb_errors: conversation.nb_errors}, messages: %{message: send_visitor_to_website(language), offers: [], quick_replies: [], buttons: [link_visit_website(language)]}}
        end

      # We are waiting for the visitor's PHONE NUMBER (for first or second time)
      user == nil && String.contains?(conversation.scope, "link_phone") ->
        language = conversation.language
        phone_number = user_msg
        case User.check_myanmar_phone_number(phone_number) do
          false -> # There is no phone number in the message
            case conversation.nb_errors == 1 do
              false -> # Ask again for phone number
                %{conversation: %{scope: "link_phone", nb_errors: 1}, messages: %{message: ask_again_phone_msg(language), offers: [], quick_replies: [], buttons: []}}
              true -> # No phone number for the 2nd time : return to beginning
                %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}
            end
          true -> # There is a phone number in the message
            other_user = Members.get_active_user_by_phone_number(phone_number)
            case other_user do
              nil -> # The phone number is not used yet : create the user
                user_params = %{phone_number: phone_number, nickname: conversation.nickname, language: language, active: true}
                case Members.create_and_track_user(user_params, conversation) do
                  {:ok, new_user} -> # The new user was created : ask his nickname
                    %{conversation: %{scope: "nickname", nb_errors: 0}, messages: %{message: ask_nickname_msg(new_user, conversation), offers: [], quick_replies: [%{title: tell_keep_nickname(language), link: "1"}], buttons: []}}
                  {:error, changeset} -> # The new user couldn't be created
                    IO.puts("Bot problem : user_creation")
                    IO.inspect(changeset)
                    %{conversation: %{scope: "error", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: []}}
                end
              other_user -> # The phone number is already used
                case conversation.psid == other_user.conversation.psid && conversation.bot_provider == other_user.conversation.bot_provider do
                  true -> # The other_user is the same user comming back with the same bot
                    case Members.update_and_track_user(other_user, conversation, %{active: true, language: language}) do
                      {:ok, user} -> # Old user keeps his number
                        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: confirm_old_phone_number_retrieved(user), offers: [], quick_replies: [], buttons: []}}
                      {:error, changeset} ->
                        IO.puts("Bot problem : user_updating")
                        IO.inspect(changeset)
                        %{conversation: %{scope: "error", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: []}}
                    end
                  false -> # There is a conflict on the phone number
                    case manage_phone_conflict(user, other_user, conversation) do
                      false -> # User creation refused for this phone number
                        %{conversation: %{scope: "link_phone", nb_errors: 0}, messages: %{message: announce_bot_conflict(conversation, other_user), offers: [], quick_replies: [], buttons: []}}
                      true -> # User creation accepted for this phone number
                        user_params = %{phone_number: phone_number, nickname: conversation.nickname, language: language, active: true}
                        case Members.create_and_track_user(user_params, conversation) do
                          {:ok, new_user} ->
                            %{conversation: %{scope: "nickname", nb_errors: 0}, messages: %{message: ask_nickname_msg(new_user, conversation), offers: [], quick_replies: [%{title: tell_keep_nickname(language), link: "1"}], buttons: []}}
                          {:error, changeset} ->
                            IO.puts("Bot problem : user_replacement")
                            IO.inspect(changeset)
                            %{conversation: %{scope: "error", nb_errors: 0}, messages: %{message: announce_technical_error(user_params.language), offers: [], quick_replies: [], buttons: []}}
                        end
                    end
                end
            end
        end

      # We are waiting the new user NICKNAME
      user != nil && conversation.scope == "nickname" ->
        language = user.language
        nickname = if user_msg == "1", do: conversation.nickname, else: user_msg
        case Members.update_user(user, %{nickname: nickname}) do
          {:ok, user} ->
            # We update the nickname in the conversation
            %{conversation: %{nickname: nickname, scope: "other_language", nb_errors: 0}, messages: %{message: ask_other_language(language), offers: [], quick_replies: propose_other_languages(language), buttons: []}}
          {:error, changeset} ->
            IO.puts("Bot problem : user_nickname")
            IO.inspect(changeset)
            case conversation.nb_errors do
              0 -> %{conversation: %{scope: "nickname", nb_errors: 1}, messages: %{message: ask_nickname_again_msg(user, conversation), offers: [], quick_replies: [%{title: tell_keep_nickname(language), link: "1"}], buttons: []}}
              # 1 -> %{conversation: %{scope: "viber_number", nb_errors: 0}, messages: %{message: ask_viber_number(user), offers: [], quick_replies: [%{title: tell_no_viber(language), link: "0"}], buttons: []}}
              1 -> %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg_full(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}
            end
        end

      # We are waiting the new user OTHER LANGUAGE
      user != nil && conversation.scope == "other_language" ->
        language = user.language
        other_language = user_msg
        Members.update_user(user, %{other_language: other_language}) # We don't check if the language is fine
        %{conversation: %{scope: "viber_number", nb_errors: 0}, messages: %{message: ask_viber_number(user), offers: [], quick_replies: [%{title: tell_no_viber(language), link: "0"}], buttons: []}}

      # We are waiting the new user VIBER NUMBER
      user != nil && conversation.scope == "viber_number" ->
        language = user.language
        if user_msg == "0" do
          %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: welcome_new_user(user), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}
        else
          case Members.update_user(user, %{viber_number: user_msg}) do
            {:ok, user} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: welcome_new_user(user), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}
            {:error, changeset} ->
              IO.puts("user_viber is not correct, we don't use it")
              IO.inspect(changeset)
              %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: welcome_new_user_without_viber_phone(user), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}
          end
        end

      #---------------------- NOTIFICATIONS -------------------------------------

      # We send a NOTIFICATION to user after treating the offer
      user != nil && conversation.scope == "offer_treated" ->
        language = user.language
        case announce.status do
          "ONLINE" -> %{conversation: conversation, messages: %{message: tell_offer_accepted(user, announce), offers: [], quick_replies: [], buttons: [link_manage_offer(language, announce), link_help(language)]}}
          "REFUSED" -> %{conversation: conversation, messages: %{message: tell_offer_refused(user, announce, user_msg), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}
        end

      # We send a NOTIFICATION to user after removing his offer
      user != nil && conversation.scope == "offer_closed" ->
        language = user.language
        %{conversation: conversation, messages: %{message: tell_offer_closed(user, announce, user_msg), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}

      #---------------------- CONVERSATIONS -------------------------------------
      # User asked for help
      user != nil && conversation.active && user_msg == "0" ->
        language = user.language
        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: inform_help(user), offers: [], quick_replies: [propose_change_language(language), propose_change_nickname(language), propose_see_offers_list(language), propose_change_phone(language), propose_quit(language, conversation.bot_provider), propose_see_details(language)], buttons: [link_visit_website(language)]}}

      # User wants to see his DETAILS
      user != nil && conversation.active && user_msg == "details" ->
        language = user.language
        nb_offers = Contents.get_user_online_offers(user) |> Kernel.length()
        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: inform_details(user, nb_offers), offers: [], quick_replies: [], buttons: []}}

      # User wants to CHANGE LANGUAGE
      user != nil && conversation.active && user_msg == "*123#" ->
        language = user.language
        %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: change_language_msg(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}

      # We are waiting for a LANGUAGE update
      user != nil && conversation.active && conversation.scope == "language" ->
        language = user.language
        new_language = String.slice(user_msg,0,1) |> convert_language()
        if language != new_language && new_language != nil do
          case Members.update_and_track_user(user, conversation, %{language: new_language}) do
            {:ok, new_user} -> %{conversation: %{scope: "other_language_update", language: new_language, nb_errors: 0}, messages: %{message: ask_other_language(new_language), offers: [], quick_replies: propose_other_languages(new_language), buttons: []}}
            {:error, changeset} ->
              IO.inspect(changeset)
              %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: nothing_to_say_msg(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
          end
        else
          %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: nothing_to_say_msg(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
        end

      # We are waiting for a OTHER LANGUAGE update
      user != nil && conversation.active && conversation.scope == "other_language_update" ->
        language = user.language
        other_language = user_msg
        Members.update_user(user, %{other_language: other_language}) # We don't check it is fine
        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: nothing_to_say_msg(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}


      # User wants to CHANGE SURNAME
      user != nil && conversation.active && user_msg == "*124#" ->
        language = user.language
        %{conversation: %{scope: "change_nickname", nb_errors: 0}, messages: %{message: change_nickname_msg(user), offers: [], quick_replies: [], buttons: []}}

      # User confirms his NEW SURNAME
      user != nil && conversation.active && conversation.scope == "change_nickname" ->
        language = user.language
        case Members.update_user(user, %{nickname: user_msg}) do
          {:ok, user} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: confirm_nickname_updated(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
          {:error, changeset} ->
            IO.puts("Bot problem : user_nickname_update")
            IO.inspect(changeset)
            %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
        end

      # User wants to UPDATE PHONE NUMBER
      user != nil && conversation.active && user_msg == "*888#" ->
        language = user.language
        %{conversation: %{scope: "update_phone", nb_errors: 0}, messages: %{message: alert_before_phone_update(user), offers: [], quick_replies: [], buttons: []}}

      # User confirms to UPDATE PHONE NUMBER
      user != nil && conversation.active && conversation.scope == "update_phone" ->
        language = user.language
        phone_number = user_msg
        case User.check_myanmar_phone_number(phone_number) do
          false -> # There is no phone number in the message : cancel the update
            %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: inform_wrong_phone_number(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
          true -> # There is a phone number in the message
            other_user = Members.get_active_user_by_phone_number(phone_number)
            cond do
              other_user == nil ->  # The phone number is not used yet
                case Members.update_and_track_user(user, conversation, %{phone_number: phone_number}) do
                  {:ok, user} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: confirm_new_phone_number_updated(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                  {:error, changeset} ->
                    IO.puts("Bot problem : user_phone_update")
                    IO.inspect(changeset)
                    %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                end
              user.phone_number == user_msg -> # Same phone number then user old one
                %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_same_phone_number(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
              true -> # The phone number is already used : conflict
                case conversation.psid == other_user.conversation.psid && conversation.bot_provider == other_user.conversation.bot_provider do
                  true -> # other_user is the same user comming back with the same bot
                    case Members.update_and_track_user(other_user, conversation, %{phone_number: phone_number}) do
                      {:ok, user} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: confirm_old_phone_number_retrieved(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                      {:error, changeset} ->
                        IO.puts("Bot problem : user_phone_coming_back")
                        IO.inspect(changeset)
                        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                    end
                  false -> # There is a conflict on the phone number
                    case manage_phone_conflict(user, other_user, conversation) do
                      false -> # User change phone number refused
                        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: announce_bot_conflict(conversation, other_user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                      true -> # User change phone number accepted
                        case Members.update_and_track_user(user, conversation, %{phone_number: phone_number}) do
                          {:ok, new_user} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: confirm_new_phone_number_updated(new_user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                          {:error, _changeset} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
                        end
                    end
                end
            end
        end

      # User wants to see his OFFERS LIST
      user != nil && conversation.active && user_msg == "*111#" ->
        language = user.language
        offers = Contents.get_user_online_offers(user)
        case Kernel.length(offers) do
          0 -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_no_active_offer(user), offers: [], quick_replies: [], buttons: [link_create_offer(user), link_help(language)]}}
          nb_offers ->
            offers_list = Enum.map(offers, fn offer -> %{offer: offer, message: detail_active_offers(user, offer), buttons: [link_manage_offer(language, offer)]} end)
            %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_nb_active_offers(user, nb_offers), offers: offers_list, quick_replies: [], buttons: []}}
        end

      # User wants to QUIT BOT
      user != nil && conversation.active == true && user_msg == "*999#" ->
        language = user.language
        answer = Members.permission_to_quit_bot(user)
        case answer do
          {:ok, _msg} -> %{conversation: %{scope: "quit_bot", nb_errors: 0}, messages: %{message: alert_before_quit_bot(user), offers: [], quick_replies: [%{title: propose_confirm_quit(language), link: "1"}, %{title: propose_cancel_quit(language), link: "0"}], buttons: []}}
          {:not_allowed, nb_offers} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_not_allowed_to_quit_bot(user, nb_offers), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
        end

      # User confirms to QUIT BOT
      user != nil && conversation.active == true && conversation.scope == "quit_bot" && user_msg == "1" ->
        language = user.language
        answer = Members.remove_bot(user, conversation)
        case answer do
          {:ok, _conversation} -> %{conversation: %{scope: "closed", active: false, nb_errors: 0}, messages: %{message: tell_bot_quitted(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
          {:not_allowed, nb_offers} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_not_allowed_to_quit_bot(user, nb_offers), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
          {:error, _msg} -> %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: tell_bot_cannot_quit(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
        end

      # User comes back after quitting
        user != nil && conversation.active == false ->
        language = user.language
        case Members.update_user(user, %{active: true}) do
          {:ok, _} -> %{conversation: %{scope: "visit_purpose", language: language, nb_errors: 0}, messages: %{message: welcome_back_msg(user), offers: [], quick_replies: [%{title: tell_registration(language), link: "1"}, %{title: tell_no_registration(language), link: "0"}], buttons: []}}
          {:error, changeset} ->
            IO.puts("Bot problem : returning_user")
            IO.inspect(changeset)
            %{conversation: %{scope: "error", nb_errors: 0}, messages: %{message: announce_technical_error(language), offers: [], quick_replies: [], buttons: []}}
        end

      # Nothing to say (fallbacks)
      user != nil && conversation.active ->
        language = user.language
        %{conversation: %{scope: "no_scope", nb_errors: 0}, messages: %{message: nothing_to_say_msg(user), offers: [], quick_replies: [], buttons: [link_visit_website(language), link_help(language)]}}
      true ->
        %{conversation: %{scope: "language", nb_errors: 0}, messages: %{message: welcome_msg_full(), offers: [], quick_replies: [%{title: propose_zawgyi(), link: "1"}, %{title: propose_unicode(), link: "2"}, %{title: propose_english(), link: "3"}], buttons: []}}

    end
  end

  # -------------------- MESSAGES   ---------------------------------------------
  #---------------------- USER REGISTRATION -------------------------------------
  defp welcome_msg_full() do
    uni = "ပေါချောင်ကောင်းမှကြိုဆိုပါတယ်။ ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\n\nWelcome to Pawchaungkaung, please choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ 1\n  -> မြန်မာ(ယူနီကုတ်)အတွက် 2\n  -> For English send 3"
  end
  defp welcome_msg() do
    uni = "ပေါချောင်ကောင်းမှကြိုဆိုပါတယ်။ ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\n\nWelcome to Pawchaungkaung, please choose your language"
  end
  defp ask_visit_purpose_msg(language) do
    uni = "အခုစကားပြောလို့ရပါပြီ။ \nပေါချောင်ကောင်းတွင်ရောင်းနိုင်ရန်အတွက်သင့်ရဲ့ဖုန်းနံပါတ်ကိုစာရင်းသွင်းမှသာ ဝယ်သူမှသင့်ထံသို့ဆက်သွယ်နိုင်မည်ဖြစ်ပါသည်။"
    case language do
      "en" -> "Now we can speak !\nTo sell on Pawchaungkaung, you need to register your mobile phone number."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_registration(language) do
    uni = "စာရင်းသွင်းလိုပါသည်။"
    case language do
      "en" -> "I want to register"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_no_registration(language) do
    uni = "စာရင်းမသွင်းလိုပါ။"
    case language do
      "en" -> "I don't want to register"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp send_visitor_to_website(language) do
    uni = "ကျေးဇူးပြု၍ပေါချောင်ကောင်းသို့ဝင်ကြည့်ပါ။"
    case language do
      "en" -> "Please visit us on Pawchaungkaung !"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_phone_msg(language) do
    uni = "သင့်ကိုဝယ်သူများမှဆက်သွယ်နိုင်ရန်အတွက် ကျေးဇူးပြုပြီးသင်၏ဖုန်းနံပါတ်ကိုရိုက်ထည့်ပါ။"
    case language do
      "en" -> "Please type your Myanmar mobile phone number for the buyers to contact you."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_again_phone_msg(language) do
    uni = "အားနာပါတယ်။ ဝယ်သူများမှသင့်ကိုဆက်သွယ်နိုင်ရန်အတွက်ပေါချောင်ကောင်းသို့သင်၏ဖုန်းနံပါတ်အမှန်ကိုရိုက်ထည့်ရန်လိုအပ်ပါသည်။"
    case language do
      "en" -> "Sorry but you must provide a valid Myanmar phone number to register on Pawchaungkaung. Please type your mobile phone number for the buyers to contact you."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_nickname_msg(user, conversation) do
    uni = "သင်၏ဖုန်းနံပါတ်နှင့် #{String.capitalize(conversation.bot_provider)} နံပါတ်တို့သည် အဆက်အသွယ်ရပြီးပြီဖြစ်သည်။ သင်၏အမည်သည်#{user.nickname}ဖြစ်ပါသည်၊ အတည်ပြုပါ (သို့) အမည်အသစ်ရေးပါ"
    case user.language do
      "en" -> "Your phone number and #{String.capitalize(conversation.bot_provider)} account are now linked.\nYour nickname is #{user.nickname}, please confirm or type a new nickname."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_nickname_again_msg(user, conversation) do
    uni = "စိတ်မကောင်းပါဘူး၊ သင့်ရဲ့အမည်သည်မှန်ကန်မှုမရှိသေးပါ။ ကျေးဇူးပြု၍သင့်အမည်ကိုစာလုံးသုံးလုံးအနည်းဆုံးရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Sorry but this nickname is not valid. Please choose a nickname between 3 and 30 characters."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_other_language(language) do
    uni = "အခြားဘာသာစကားပြောပါသလား"
    case language do
      "en" -> "Do you speak another language ?"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_keep_nickname(language) do
    uni = "ဤအမည်ကိုအတည်ပြုပါ။"
    case language do
      "en" -> "Keep this nickname"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp ask_viber_number(user) do
    uni = "ဝယ်သူများမှသင့်ထံသို့ Viber မှတဆင့်ဆက်သွယ်စေလိုပါက သင့်ရဲ့ Viber နံပါတ်ကိုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "If you want people to contact you on Viber please type your Myanmar Viber number now."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_no_viber(language) do
    uni = "ကျွန်တော်/ကျွန်မထံသို့ Viber ဖြင့်မဆက်သွယ်စေလိုပါ"
    case language do
      "en" -> "Don't contact me on Viber"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp welcome_new_user(user) do
    uni = "ကျေးဇူးတင်ပါတယ် #{user.nickname}, သင့်အတွက်ပေါချောင်ကောင်းတွင်စာရင်းသွင်းပြီးပါပြီ။\n သင့်ဖုန်းနံပါတ်မှာ #{user.phone_number}#{show_viber_number(user)} ဖြစ်ပါတယ်။ ကျေးဇူးပြု၍သင့်ရဲ့ပထပဆုံးရောင်းရန်ပစ္စည်းကြော်ငြာကိုပြုလုပ်ပါ။ "
    case user.language do
      "en" -> "Thanks #{user.nickname}, you are now registered on Pawchaungkaung !\nYour phone number is #{user.phone_number}#{show_viber_number(user)}.\nPlease create your first offer !"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp show_viber_number(user) do
    case user.viber_number do
      nil -> ""
      _ ->
        uni = "ပြီးနောက် သင့်ရဲ့ Viber နံပါတ်မှာ #{user.viber_number}"
        case user.language do
          "en" -> " and your Viber number is #{user.viber_number}"
          "my" -> uni
          "dz" -> Rabbit.uni2zg(uni)
        end
    end
  end
  defp welcome_new_user_without_viber_phone(user) do
    uni = "ကျေးဇူးတင်ပါတယ် #{user.nickname}, သင့်အတွက်ပေါချောင်ကောင်းတွင်စာရင်းသွင်းပြီးပါပြီ။\nကျေးဇူးပြု၍ #{offer_form_link(user.phone_number)} သို့ဝင်ကြည့်ပါ။"
    case user.language do
      "en" -> "Thanks #{user.nickname}, you are now registered on Pawchaungkaung !\nPlease create your first offer !"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  #---------------------- NOTIFICATIONS -----------------------------------------
  defp tell_offer_accepted(user, offer) do
    uni = "မင်္ဂလာပါ #{user.nickname} သင်၏ရောင်းရန်ပစ္စည်းကြော်ငြာကိုတင်လိုက်ပြီဖြစ်ပါသည်။ ၎င်းကို #{LayoutView.format_date(offer.validity_date)} အထိ (၁)လအကြာ ကြော်ငြာတင်ထားမည် ဖြစ်သည်။"
    case user.language do
      "en" -> "Hi #{user.nickname}, your offer is now published ! It will be online for 1 month until #{LayoutView.format_date(offer.validity_date)}."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_offer_refused(user, offer, cause) do
    uni = "မင်္ဂလာပါ #{user.nickname}၊ စိတ်မကောင်းပါဘူးသင့်ရဲ့ကြော်ငြာဟာ #{cause} ကြောင့်ငြင်းပယ်ခြင်းခံရပါတယ်။ ကျေးဇူးပြု၍ကြော်ငြာအသစ်တစ်ဖန်ပြန်လုပ်ပါ"
    case user.language do
      "en" -> "Hi #{user.nickname}, we are sorry but your offer was refused because #{cause}. Please create a new offer."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_offer_closed(user, offer, cause) do
    uni = "မင်္ဂလာပါ #{user.nickname}၊ သင့်ရဲ့ #{offer.title} ကြော်ငြာကို#{cause}ပိတ်လိုက်ပါပြီ။"
    case user.language do
      "en" -> "Hi #{user.nickname}, your offer #{offer.title} has been closed #{cause}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  #---------------------- CONVERSATIONS -----------------------------------------
  defp inform_help(user) do
      uni = "ကျွန်တော်/မ တို့သည် #{user.nickname} ကိုကူညီရန်အသင့်ပါ၊"
    case user.language do
      "en" -> "We are ready to help #{user.nickname}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp inform_details(user, nb_offers) do
    uni = "သင့်အမည်သည် #{user.nickname} ဖြစ်ပြီး သင့်ဖုန်းနံပါတ်သည် #{user.phone_number}၊ #{inform_viber_number(user)} သင့်ထံတွင်လက်ရှိကြော်ငြာ #{nb_offers} ခုရှိပါသည်။"
    case user.language do
      "en" -> "Your nickname is #{user.nickname}, your phone number is #{user.phone_number}, #{inform_viber_number(user)}you have #{nb_offers} active offers."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp inform_viber_number(user) do
    case user.viber_number do
      nil -> ""
      _ ->
        uni = "သင့်ရဲ့ Viber နံပါတ်သည် #{user.viber_number} ဖြစ်သည်။"
        case user.language do
          "en" -> "your Viber number is #{user.viber_number}, "
          "my" -> uni
          "dz" -> Rabbit.uni2zg(uni)
        end
    end
  end
  defp change_language_msg() do
    uni = "ကျေးဇူးပြု၍သင်၏ဘာသာစကားကိုရွေးချယ်ပါ"
    "#{Rabbit.uni2zg(uni)}\n\nPlease choose your language."
  end
  defp change_nickname_msg(user) do
    uni = "ကျေးဇူးပြု၍သင့်အမည်အသစ်ကိုရိုက်ထည့်ပါ။"
    case user.language do
      "en" -> "Ok #{user.nickname}, please type your new username now."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp confirm_nickname_updated(user) do
    uni = "သင့်ရဲ့အမည်အသစ်ကိုပြောင်းပြီးပါပြီ၊"
    case user.language do
      "en" -> "Ok #{user.nickname}, we updated your username."
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
  defp inform_wrong_phone_number(user) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}။ ဒီနံပါတ်မှားနေပါတယ်။ နောက်တဖန်ထပ်ကြိုးစားကြည့်ပါ။"
    case user.language do
      "en" -> "Sorry #{user.nickname}, this is not a good phone number. Please try again."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp confirm_new_phone_number_updated(user) do
    uni = "အဆင်ပြေပါပြီ #{user.nickname},  သင့်ဖုန်းနံပါတ်အသစ်ပြန်ပြင်ပြိးဖြစ်သည်။"
    case user.language do
      "en" -> "Perfect #{user.nickname}, your phone number was updated."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_same_phone_number(user) do
    uni = "သင်သိလား သင့်ရဲ့ဖုန်းနံပါတ်က ပေါချောင်ကောင်းရဲ့ #{String.capitalize(user.conversation.bot_provider)} နဲ့ အဆက်အသွယ်ရနေပါပြီ။ :)"
    case user.language do
      "en" -> "You know what #{user.nickname}, your phone number was already linked to this #{String.capitalize(user.conversation.bot_provider)} account :)"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp confirm_old_phone_number_retrieved(user) do
    uni = "အဆင်ပြေပါပြီ #{user.nickname}, သင့်ရဲ့ ဖုန်းနံပါတ်ကိုပြန်ရပါပြီ။"
    case user.language do
      "en" -> "Perfect #{user.nickname}, you get back your phone number."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp announce_bot_conflict(conversation, other_user) do
    uni = "စိတ်မကောင်းပါဘူး #{conversation.nickname} ဒီဖုန်းနံပါတ်ကိုအခြားသူမှအသုံးပြုပြီးဖြစ်ပါတယ်။ ကျေးဇူးပြု၍ ရှေးဦးစွာအချိတ်အဆက်ဖြုတ်လိုက်ပါ (သို့) ပေါချောင်ကောင်းသို့ဆက်သွယ်ပါ။"
    case conversation.language do
      "en" -> "Sorry #{conversation.nickname}, this phone number is used by another user on #{other_user.conversation.bot_provider}. Please unlink it first or contact us."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_no_active_offer(user) do
    uni = "သင့်မှာမည်သည့်ကြော်ငြာမျှမရှိသေးပါ။ ကျေးဇူးပြု၍သင်၏ပထမဆုံးကြော်ငြာကို်တင်လိုက်ပါ။"
    case user.language do
      "en" -> "You don't have any active offer yet. Please create your first offer !"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_nb_active_offers(user, nb_offers) do
    uni = "Ok #{user.nickname}၊ သင့်တွင်လက်ရှိကြော်ငြာ #{nb_offers} ခုရှိပါသည်။"
    case user.language do
      "en" -> "Ok #{user.nickname}, you have #{nb_offers} active offers."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp detail_active_offers(user, offer) do
    uni = "သင့်ကြော်ငြာကို #{offer.nb_clic} ကြိမ်ခန့်ဝင်ရောက်ကြည့်ရှုကြပြီးဖြစ်သည်။ #{LayoutView.format_date(offer.validity_date)} အထိကြော်ငြာတင်ထားမည်။"
    case user.language do
      "en" -> "Your offer has been viewed #{offer.nb_clic} times and will be online until #{LayoutView.format_date(offer.validity_date)}."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp alert_before_quit_bot(user) do
    uni = "သင့်ရဲ့ ပေါချောင်ကေင်းနှင့် ချိတ်ဆက်ထားမှုကိုပြန်လည်ဖြုတ်ချင်သည်မှာသေခြာပြီလား။ ချိတ်ဆက်ထားမှုကိုဖြုတ်လိုက်ပြီးလျင် ကြော်ငြာအသစ်တင်နိုင်ရန်အတွက် တစ်ဖန်ပြန်လည်စာရင်းသွင်းရမည်ဖြစ်သည်။"
    case user.language do
      "en" -> "Are you sure you want to quit Pawchaungkaung ? If you quit, you will need to register again to create new offer."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_bot_quitted(user) do
    uni = "သင့်ရဲ့ #{String.capitalize(user.conversation.bot_provider)} ကြော်ငြာကိုပိတ်လိုက်ပါပြီ။ မကြာခင် ပေါချောင်ကေင်းမှာပြန်ဆုံကြမယ်နော်။"
    case user.language do
      "en" -> "Your #{String.capitalize(user.conversation.bot_provider)} account has been closed.\nHope to see you soon on Pawchaungkaung !"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_not_allowed_to_quit_bot(user, nb_offers) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}, သင့်ထံမှာ ကြော်ငြာ #{nb_offers} ရှိနေသေးသောကြောင့် သင့်ရဲ့ #{String.capitalize(user.conversation.bot_provider)} အချိတ်အဆက်ကိုဖြုတ်၍မရပါ"
    case user.language do
      "en" -> "Sorry #{user.nickname}, we cannot close your #{String.capitalize(user.conversation.bot_provider)} account because you still have #{nb_offers} offers."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp tell_bot_cannot_quit(user) do
    uni = "စိတ်မကောင်းပါဘူး#{user.nickname}၊ သင်ရဲ့ #{String.capitalize(user.conversation.bot_provider)} စာရင်းသွင်းထားမှုကိုဖြုတ်၍မရပါ။ ကျေးဇူးပြု၍ ပေါချောင်ကောင်းကိုဆက်သွယ်ပါ။"
    case user.language do
      "en" -> "Sorry #{user.nickname}, we cannot close your #{String.capitalize(user.conversation.bot_provider)} account. Please contact us."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp nothing_to_say_msg(user) do
    uni = "မင်္ဂလာပါ #{user.nickname}။"
    case user.language do
      "en" -> "Hi #{user.nickname} !\n#{say_something_neutral(user.language)}"
      "my" -> "#{uni}\n#{say_something_neutral(user.language)}"
      "dz" -> "#{Rabbit.uni2zg(uni)}\n#{say_something_neutral(user.language)}"
    end
  end
  defp welcome_back_msg(user) do
    uni = "ပေါချောင်ကေင်းမှတစ်ဖန်ကြိုဆိုပါတယ် #{user.nickname}။"
    case user.language do
      "en" -> "Welcome back to Pawchaungkaung #{user.nickname} !"
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

  #---------------------- LINK REPLIES -----------------------------------------
  defp link_create_offer(user) do
    uni = "ကြော်ငြာကိုတင်လိုက်ရန်"
    title = case user.language do
      "en" -> "Create an offer"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: offer_form_link(user.phone_number), action: "open-url"}
  end
  defp link_visit_website(language) do
    uni = "ပေါချောင်ကေင်းသို့ဝင်ကြည့်ပါ။"
    title = case language do
      "en" -> "Visit Pawchaungkaung"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: website_url(), action: "open-url"}
  end
  defp link_help(language) do
    uni = "အကူအညီရယူရန်"
    title = case language do
      "en" -> "Get help"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "0", action: "reply"}
  end
  defp link_manage_offer(language, offer) do
    uni = "သင်၏ကြော်ငြာကိုသင့်အလိုကျစီမံနိုင်ရန်"
    title = case language do
      "en" -> "Manage your offer"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
     %{title: title, link: offer_view_link(offer.id), action: "open-url"}
  end

  #---------------------- QUICK REPLIES -----------------------------------------
  defp propose_zawgyi() do
    "ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္"
  end
  defp propose_other_languages(language) do
    only_burmese = "မြန်မာဘာသာစကားသာ" # ဘာသာစကား
    english = "အင်္ဂလိပ်ဘာသာစကား"
    chinese = "တရုတ်ဘာသာစကား"
    japanese = "ဂျပန်ဘာသာစကား"
    korean = "ကိုရီးရားဘာသာစကား"
    case language do
      "en" -> [%{title: "Burmese", link: "bi"}, %{title: "Only English", link: "0"}]
      "my" -> [%{title: english, link: "en"}, %{title: chinese, link: "cn"}, %{title: japanese, link: "jp"}, %{title: korean, link: "kr"}, %{title: only_burmese, link: "0"}]
      "dz" -> [
        %{title: Rabbit.uni2zg(english), link: "en"}, %{title: Rabbit.uni2zg(chinese), link: "cn"},
        %{title: Rabbit.uni2zg(japanese), link: "jp"}, %{title: Rabbit.uni2zg(korean), link: "kr"},
        %{title: Rabbit.uni2zg(only_burmese), link: "0"}
      ]
    end
  end
  defp propose_see_details(language) do
    uni = "သင့်ရဲ့အချက်အလက်များကိုကြည့်ပါ။"
    title = case language do
      "en" -> "See your details"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "details"}
  end
  defp propose_unicode() do
    "မြန်မာ(ယူနီကုတ်)အတွက်"
  end
  defp propose_english() do
    "English"
  end
  defp propose_change_language(language) do
    uni = "ဘာသာစကားပြောင်းရန်"
    title = case language do
      "en" -> "Change language"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "*123#"}
  end
  defp propose_change_nickname(language) do
    uni = "အမည်ပြောင်းရန်"
    title = case language do
      "en" -> "Change nickname"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "*124#"}
  end
  defp propose_see_offers_list(language) do
    uni = "သင့်ကြော်ငြာများကိုကြည့်ရန်"
    title = case language do
      "en" -> "See active offers"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "*111#"}
  end
  defp propose_change_phone(language) do
    uni = "သင်ဖုန်းနံပါတ်ပြောင်းရန်"
    title = case language do
      "en" -> "Change phone number"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "*888#"}
  end
  defp propose_quit(language, bot) do
    uni = "#{bot} မှထွက်ရန်"
    title = case language do
      "en" -> "Quit #{bot}"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
    %{title: title, link: "*999#"}
  end
  defp propose_confirm_quit(language) do
    uni = "ပေါချောင်ကောင်းမှထွက်ရန်"
    case language do
      "en" -> "Quit Pawchaungkaung."
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end
  defp propose_cancel_quit(language) do
    uni = "ပယ်ဖျက်ရန်"
    case language do
      "en" -> "Cancel"
      "my" -> uni
      "dz" -> Rabbit.uni2zg(uni)
    end
  end

  #---------------------- CUSTOM FUNCTIONS -----------------------------------------
  defp convert_language(language_key) do
    case language_key do
      "1" -> "dz"
      "2" -> "my"
      "3" -> "en"
      _ -> nil
    end
  end

  defp offer_form_link(phone_number) do
    "#{website_url()}/offer/new/#{phone_number}"
  end

  def offer_view_link(offer_id) do
    path = "/user/offer/#{offer_id}" |> Cipher.sign_url()
    "#{website_url()}#{path}"
  end

  defp website_url() do
    Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:website_url]
  end

  defp manage_phone_conflict(user, other_user, conversation) do
    cond do
      other_user.active == true -> false # Other user bot active = forbidden
      Contents.get_user_active_offers(other_user) != [] -> false # Other user has active offers = forbidden
      true ->
        Members.update_and_track_user(other_user, conversation, %{active: false}) # We cancel other user forever (history)
        true # We accept the usage of this phone number
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
