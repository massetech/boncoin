defmodule BoncoinWeb.MessengerConversationTest do
  use BoncoinWeb.ConnCase
  use Mockery
  use ExUnit.Case, async: true
  import Mockery.Assertions
  import Plug.Conn
  import Boncoin.{Factory}
  alias BoncoinWeb.MessengerController
  alias Boncoin.Auth.Guardian
  alias Boncoin.{Members, Contents, MessengerApi}
  alias Boncoin.Members.{User, Conversation}
  alias Boncoin.Contents.{Announce}
  alias Boncoin.CustomModules.BotDecisions
  alias Boncoin.Repo

  @moduletag :MessengerConversationModule
  @moduletag :Module

  defp current_user_plug(messenger_id) do
    # Do the job of API plug
    conn = Phoenix.ConnTest.build_conn()
      |> Phoenix.Controller.put_view(BoncoinWeb.MessengerView) # Needed for the first welcome msg in json response
    case Members.get_active_user_by_bot_id(messenger_id, "messenger") do
      nil ->
        conn
          |> assign(:current_user, nil)
      user ->
        conn
          |> assign(:current_user, user)
    end
  end

  defp tester_messenger_id() do
    Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:messenger_user_id]
  end

  defp build_normal_params(messenger_id, msg) do
    %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => msg}}]}]}
  end
  defp receive_msg(messenger_id, params) do
    conn = current_user_plug(messenger_id)
    MessengerController.incoming_message(conn, params)
  end

  defp assert_welcome_msg_answered(conn, scope, messenger_id) do
    conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
    assert conversation.scope == scope
    assert conn.resp_body =~ "Welcome to Pawchaungkaung, please choose your language"
  end
  defp assert_msg_answered(scope, messenger_id, msg) do
    conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
    cond do
      scope == :update ->
        assert_called MessengerApi, :send_message, ["UPDATE", ^messenger_id, _msg, _quick_replies, _buttons, _offer] # Can't count the nb of calls in same test
      msg == "" ->
        assert conversation.scope == scope
        assert_called MessengerApi, :send_message, ["RESPONSE", ^messenger_id, _msg, _quick_replies, _buttons, _offer] # Can't count the nb of calls in same test
      true ->
        assert conversation.scope == scope
        assert_called MessengerApi, :send_message, ["RESPONSE", ^messenger_id, ^msg, _quick_replies, _buttons, _offer]
    end
  end
  defp assert_admin_informed(admin_user, msg) do
    admin_psid = admin_user.conversation.psid
    assert_called MessengerApi, :send_message, [nil, ^admin_psid, ^msg, _quick_replies, _buttons, _offer]
  end

  describe "Messenger conversation workflow" do
    @tag :MessengerRegistration
    test "user registration" do
      Repo.delete_all(Announce)
      Repo.delete_all(User)
      Mockery.History.enable_history()
      # Initiate visitor
      messenger_id = tester_messenger_id()
      messenger_name = "Mr messenger 1234"
      phone_number = "09110000002"
      # Initiate other user
      other_messenger_id = "other_messenger_id"
      other_user = insert(:user, %{phone_number: "09110000001"})
      insert(:conversation, %{user_id: other_user.id, psid: other_messenger_id})
      other_user = Members.get_user(other_user.id) # Preload conversation

      # 1.1) Unknown user opens conversation with Reference
        IO.puts("test 1.1")
        params = %{"entry" => [%{"messaging" => [%{"postback" => %{"referral" => %{"ref" => "a_reference"}}, "sender" => %{"id" => messenger_id}}]}]}
        result = receive_msg(messenger_id, params)
        assert_welcome_msg_answered(result, "language", messenger_id)
      # 1.2) Unknown user opens conversation with Payload
        IO.puts("test 1.2")
        params = %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "messenger_direct"}, "sender" => %{"id" => messenger_id}}]}]}
        result = receive_msg(messenger_id, params)
        assert_welcome_msg_answered(result, "language", messenger_id)
      # 2) Unknown user selects a wrong language
        IO.puts("test 2")
        receive_msg(messenger_id, build_normal_params(messenger_id, "wrong_language"))
        assert_msg_answered("language", messenger_id, BotDecisions.welcome_msg())
      # 3) Unknown user selects his language
        IO.puts("test 3")
        receive_msg(messenger_id, build_normal_params(messenger_id, "3"))
        assert_msg_answered("visit_purpose", messenger_id, BotDecisions.ask_visit_purpose_msg("en"))
      # 4) Unknown user says he wants to register
        IO.puts("test 4")
        receive_msg(messenger_id, build_normal_params(messenger_id, "1"))
        assert_msg_answered("link_phone", messenger_id, BotDecisions.ask_phone_msg("en"))
      # 5.1) Unknown user types wrong phone number
        IO.puts("test 5.1")
        receive_msg(messenger_id, build_normal_params(messenger_id, "wrong_phone_number"))
        assert_msg_answered("link_phone", messenger_id, BotDecisions.ask_again_phone_msg("en"))
      # 5.2) Unknown user types wrong phone number 2nd time and receives welcome msg
        IO.puts("test 5.2")
        receive_msg(messenger_id, build_normal_params(messenger_id, "wrong_phone_number"))
        assert_msg_answered("language", messenger_id, BotDecisions.welcome_msg())
      # 6) Unknown user selects language and already used phone number
        IO.puts("test 6")
        receive_msg(messenger_id, build_normal_params(messenger_id, "3"))
        receive_msg(messenger_id, build_normal_params(messenger_id, "1"))
        receive_msg(messenger_id, build_normal_params(messenger_id, other_user.phone_number))
        conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
        assert_msg_answered("link_phone", messenger_id, BotDecisions.announce_bot_conflict(conversation, other_user))
      # 7) User types a free phone number : user is created
        IO.puts("test 7")
        # Empty all users to make sure the first one will be admin
        Repo.delete_all(User)
        receive_msg(messenger_id, build_normal_params(messenger_id, phone_number))
        user = Members.get_active_user_by_bot_id(messenger_id, "messenger")
        assert user.conversation.origin == "a_reference"
        assert_msg_answered("nickname", messenger_id, BotDecisions.ask_nickname_msg(user, user.conversation))
        assert_admin_informed(user, Members.new_user_msg(user)) # This user is an admin
      # 8) User confirms his nickname
        IO.puts("test 8")
        receive_msg(messenger_id, build_normal_params(messenger_id, "1"))
        assert_msg_answered("other_language", messenger_id, BotDecisions.ask_other_language("en"))
      # 9) User says he speaks also burmese
        IO.puts("test 9")
        receive_msg(messenger_id, build_normal_params(messenger_id, "my"))
        assert_msg_answered("viber_number", messenger_id, BotDecisions.ask_viber_number("en"))
        user_1 = Members.get_active_user_by_bot_id(messenger_id, "messenger")
        assert user_1.other_language == "my"
      # 10) User gives his Messenger number
        IO.puts("test 10")
        receive_msg(messenger_id, build_normal_params(messenger_id, "091234567"))
        user = Members.get_active_user_by_bot_id(messenger_id, "messenger")
        assert_msg_answered("no_scope", messenger_id, BotDecisions.welcome_new_user(user))
        assert user.viber_number == "091234567"
    end

    @tag :MessengerConversation
    test "user conversation" do
      Repo.delete_all(Announce)
      Repo.delete_all(User)
      Mockery.History.enable_history()
      # Initiate user tester
      messenger_id = tester_messenger_id()
      phone_number = "09110000012"
      user = insert(:admin_user, %{phone_number: phone_number, language: "my"}) # This user will be admin
      insert(:conversation, %{scope: "no_scope", origin: "#{user.id}", user_id: user.id, psid: tester_messenger_id()})
      user = Members.get_user(user.id) # Preload conversation
      # Initiate other user 1
      other_user = insert(:user, %{phone_number: "09110000013"})
      insert(:conversation, %{scope: "no_scope", user_id: other_user.id, psid: "other_messenger_id"})
      other_user = Members.get_user(other_user.id) # Preload conversation
      other_user_psid = other_user.conversation.psid
      # Initiate other user 2
      other_user_2 = insert(:user, %{phone_number: "09110000014", active: false})
      insert(:conversation, %{scope: "no_scope", user_id: other_user_2.id, psid: "other_messenger_2_id", active: false})
      other_user_2 = Members.get_user(other_user_2.id) # Preload conversation
      # Other params
      free_phone_number = "09110000020"

      # 21) User says nothing special
        IO.puts("test 21")
        receive_msg(messenger_id, build_normal_params(messenger_id, "blablabla"))
        assert_msg_answered("no_scope", messenger_id, "")
      # 22) User wants to get help
        IO.puts("test 22")
        receive_msg(messenger_id, build_normal_params(messenger_id, "0"))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.inform_help(user))
      # 23.1) User wants to change his language
        IO.puts("test 23.1")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*123#"))
        assert_msg_answered("language", messenger_id, BotDecisions.change_language_msg())
      # 23.2) User changes his language to EN
        IO.puts("test 23.2")
        receive_msg(messenger_id, build_normal_params(messenger_id, "3"))
        user = Members.get_user(user.id)
        assert user.language == "en"
        assert user.conversation.language == "en"
        assert_msg_answered("other_language_update", messenger_id, BotDecisions.ask_other_language("en"))
      # 23.3) User selects his other language to chinese
        IO.puts("test 23.3")
        receive_msg(messenger_id, build_normal_params(messenger_id, "cn"))
        user = Members.get_user(user.id)
        assert user.other_language == "cn"
        assert_msg_answered("no_scope", messenger_id, "")
      # 24.1) User wants to change his phone number and types his own phone number
        IO.puts("test 24.1")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*888#"))
        assert_msg_answered("update_phone", messenger_id, BotDecisions.alert_before_phone_update(user))
        receive_msg(messenger_id, build_normal_params(messenger_id, user.phone_number))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.tell_same_phone_number(user))
      # 24.2) User wants to change his phone number ant types a phone number already used
        IO.puts("test 24.2")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*888#"))
        receive_msg(messenger_id, build_normal_params(messenger_id, other_user.phone_number))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.announce_bot_conflict(user.conversation, other_user))
      # 24.3) User wants to change his phone number ant types a an old inactive phone number
        IO.puts("test 24.3")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*888#"))
        receive_msg(messenger_id, build_normal_params(messenger_id, other_user_2.phone_number))
        user = Members.get_user(user.id)
        assert user.phone_number == other_user_2.phone_number
        assert_msg_answered("no_scope", messenger_id, BotDecisions.confirm_new_phone_number_updated(user))
      # 24.4) User wants to change his phone number ant types a phone number which is free
        IO.puts("test 24.4")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*888#"))
        receive_msg(messenger_id, build_normal_params(messenger_id, free_phone_number))
        user = Members.get_user(user.id)
        assert user.phone_number == free_phone_number
        assert_msg_answered("no_scope", messenger_id, BotDecisions.confirm_new_phone_number_updated(user))
      # 25.1) User wants to receive list of his active offers but has no offer yet
        IO.puts("test 25.1")
        receive_msg(messenger_id, build_normal_params(messenger_id, "*111#"))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.tell_no_active_offer(user))
      # 25.2) User wants to receive list of his active offers and has offers
        IO.puts("test 25.2")
        insert_list(2, :announce, %{user_id: user.id, status: "ONLINE"})
        receive_msg(messenger_id, build_normal_params(messenger_id, "*111#"))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.tell_nb_active_offers(user, 2))
      # 26) User wants to quit messenger but has active offers
        IO.puts("test 26")
        pending_offer = insert(:announce, %{user_id: user.id, status: "PENDING", title: "bike"})
        receive_msg(messenger_id, build_normal_params(messenger_id, "*999#"))
        assert_msg_answered("no_scope", messenger_id, BotDecisions.tell_not_allowed_to_quit_bot(user, 3))
      # 27.1) Known user receives a msg after treating his pending offer
        IO.puts("test 27.1")
        Contents.treat_announce(user, %{"announce_id" => pending_offer.id, "validate" => "true", "cause" => "ACCEPTED", "category_id" => pending_offer.category_id})
        accepted_offer = Contents.get_announce!(pending_offer.id)
        assert_msg_answered(:update, messenger_id, BotDecisions.tell_offer_accepted(user, accepted_offer))
      # 27.2) Known user posting offer is counted in embassadors KPI
        IO.puts("test 27.2")
        filter = %{month: Kernel.inspect(Timex.now().month), year: Kernel.inspect(Timex.now().year)}
        embassador_kpi = Members.get_embassador_kpi("#{user.id}", filter)
        assert embassador_kpi == %{nb_new_publishers: 1, nb_new_users: 1, nb_publishers: 1, nb_user: 1}
      # 28) User wants to quit and confirms it
        IO.puts("test 28")
        offers = Contents.get_user_active_offers(user)
        for offer <- offers do
          Contents.update_announce(offer, %{status: "CLOSED"})
        end
        receive_msg(messenger_id, build_normal_params(messenger_id, "*999#"))
        assert_msg_answered("quit_bot", messenger_id, BotDecisions.alert_before_quit_bot(user))
        receive_msg(messenger_id, build_normal_params(messenger_id, "1"))
        assert Members.get_active_user_by_bot_id(messenger_id, "messenger") == nil
        assert_msg_answered("closed", messenger_id, BotDecisions.tell_bot_quitted(user))
      # 28.1) Another user takes this phone number
        IO.puts("test 28.1")
        receive_msg(other_user_psid, build_normal_params(other_user_psid, "*888#"))
        receive_msg(other_user_psid, build_normal_params(other_user_psid, free_phone_number))
        other_user = Members.get_user(other_user.id)
        assert other_user.phone_number == free_phone_number
        assert_msg_answered("no_scope", other_user_psid, BotDecisions.confirm_new_phone_number_updated(other_user))
      # 28.2) The history of 2 users is kept
        IO.puts("test 28.2")
        old_phones = Members.get_phones_by_user_id(user.id)
        assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000012" end) != nil
        assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000014" end) != nil
        assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000020" end) != nil
    end
  end

end
