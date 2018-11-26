defmodule BoncoinWeb.ConversationTest do
  use BoncoinWeb.ConnCase
  import Boncoin.{Factory}
  import Boncoin.CustomModules.BotDecisions
  alias BoncoinWeb.MessengerController
  alias Boncoin.{Members, Contents, ViberApi, MessengerApi}
  alias Boncoin.Auth.Guardian
  import Mockery.Assertions
  import Plug.Conn
  use Mockery

  @moduletag :ConversationModule
  @moduletag :Module

  defp init_messenger_params(messenger_id) do
    %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD"},"sender" => %{"id" => messenger_id}}]}], "object" => "page"}
  end
  defp messenger_params(messenger_id, user_msg) do
    %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}], "object" => "page"}
  end
  defp receive_messenger_msg(conn, messenger_id, messenger_params) do
    case Members.get_active_user_by_bot_id(messenger_id, "messenger") do
      nil ->
        conn
          |> assign(:current_user, nil) # To do the job of API plug
          |> MessengerController.incoming_message(messenger_params)
      user ->
        conn
          |> assign(:current_user, user) # To do the job of API plug
          |> MessengerController.incoming_message(messenger_params)
    end
  end
  defp assert_sent_messenger_msg(scope, messenger_id, msg) do
    conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
    assert conversation.scope == scope
    case msg do
      "" -> assert_called MessengerApi, :send_message, [^messenger_id, _] # Can't count the nb of calls in same test
      msg -> assert_called MessengerApi, :send_message, [^messenger_id, ^msg]
    end
  end
  defp assert_sent_messenger_msg(messenger_id, msg) do
    case msg do
      "" -> assert_called MessengerApi, :send_message, [^messenger_id, _] # Can't count the nb of calls in same test
      msg -> assert_called MessengerApi, :send_message, [^messenger_id, ^msg]
    end
  end

  @tag :case1
  describe "Messenger conversation workflow" do
    @describetag :member_authenticated
    test "case 1", %{conn: conn} do
      Mockery.History.enable_history()
      admin_user = insert(:admin_user)
      admin_conn = Phoenix.ConnTest.build_conn()
        |> Guardian.Plug.sign_in(admin_user, %{"typ" => "user-access"})
      messenger_id = "messenger_1234"
      other_messenger_id = "messenger_12345"
      other_active_user = insert(:user, %{phone_number: "09110000001"})
      other_inactive_user = insert(:user, %{phone_number: "09110000003", active: false})
      # 1) Unknown user opens conversation
        IO.puts("test 1")
        receive_messenger_msg(conn, messenger_id, init_messenger_params(messenger_id))
        assert_sent_messenger_msg("language", messenger_id, "")
      # 2) Unknown user selects a wrong language
        IO.puts("test 2")
        messenger_params = messenger_params(messenger_id, "uiczicb")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("language", messenger_id, "")
      # 3) Unknown user selects language and receives question to phone number
        IO.puts("test 3")
        messenger_params = messenger_params(messenger_id, "3")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("link_phone_1", messenger_id, "Now we can speak! Please also type your mobile phone number.")
      # 4) Unknown user types wrong phone number and receives 2nd question for phone number
        IO.puts("test 4")
        messenger_params = messenger_params(messenger_id, "090201020102")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("link_phone_2", messenger_id, "Sorry but we need to identify you. Please type your mobile phone number.")
      # 5) Unknown user types wrong phone number 2nd time and receives welcome msg
        IO.puts("test 5")
        messenger_params = messenger_params(messenger_id, "08000000002")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("language", messenger_id, "")
      # 6) Unknown user selects language and receives question to phone number
        IO.puts("test 6")
        messenger_params = messenger_params(messenger_id, "3")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("link_phone_1", messenger_id, "Now we can speak! Please also type your mobile phone number.")
      # 7) Unknown user types already used phone number and receives question to phone number
        IO.puts("test 7")
        messenger_params = messenger_params(messenger_id, "09110000001")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("link_phone_1", messenger_id, "Sorry mr_X, this phone number is used by another user. Please unlink it first or contact us.")
      # 8) Unknown user types a free phone number and receives confirmation
        IO.puts("test 8")
        messenger_params = messenger_params(messenger_id, "09110000002")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "Your phone number and Messenger account are now linked.\nPlease visit us on https://www.pawchaungkaung.com/offer/new/09110000002")
      # 9) Know user says nothing special
        IO.puts("test 9")
        messenger_params = messenger_params(messenger_id, "blablablabla")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "")
      # 10) Known user wants to get help
        IO.puts("test 10")
        messenger_params = messenger_params(messenger_id, "0")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "We are happy to help mr_X,\n\nchange language *123#\nsee your offers *111#\nchange phone number *888#\nquit Messenger *999#")
      # 11) Known user wants to change his language for MY
        IO.puts("test 11")
        messenger_params = messenger_params(messenger_id, "*123#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("language", messenger_id, "ေက်းဇူးျပဳ၍သင္၏ဘာသာစကားကိုေ႐ြးခ်ယ္ပါ\n\nPlease choose your language\n\n  -> ျမန္မာ(ေဇာ္ဂ်ီ)အတြက္ 1\n  -> မြန်မာ(ယူနီကုတ်)အတွက် 2\n  -> For English send 3")
        messenger_params = messenger_params(messenger_id, "2")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "")
        user_1 = Members.get_active_user_by_bot_id(messenger_id, "messenger")
        conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
        assert user_1.language == "my"
        assert conversation.language == "my"
        Members.udpate_and_track_user(user_1, %{language: "en"})
        Members.update_conversation(conversation, %{language: "en"})
      # 12) Known user wants to change his phone number, types his own phone number and receives funny msg
        IO.puts("test 12")
        messenger_params = messenger_params(messenger_id, "*888#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("update_phone", messenger_id, "All your offers will be moved to this new phone number. If you are sure please type your new phone number now.")
        messenger_params = messenger_params(messenger_id, "09110000002")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "You know what mr_X, your phone number was already linked to this Messenger account :)")
      # 13) Known user wants to change his phone number, types a number used by active user and receives alert msg
        IO.puts("test 13")
        messenger_params = messenger_params(messenger_id, "*888#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("update_phone", messenger_id, "")
        messenger_params = messenger_params(messenger_id, "09110000001")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "Sorry mr_X, this phone number is used by another user. Please unlink it first or contact us.")
      # 14) Known user wants to change his phone number, types an old phone number and receives confirmation
        IO.puts("test 14")
        messenger_params = messenger_params(messenger_id, "*888#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("update_phone", messenger_id, "")
        messenger_params = messenger_params(messenger_id, "09110000003")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "Perfect mr_X, your phone number was updated.\n Please visit us on https://www.pawchaungkaung.com")
      # 15) Known user wants to receive list of his active offers but has no offer yet
        IO.puts("test 15")
        messenger_params = messenger_params(messenger_id, "*111#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "You don't have any offer yet. Please create your first offer on https://www.pawchaungkaung.com/offer/new/09110000003")
      # 16) Known user wants to quit messenger but has active offers
        IO.puts("test 16")
        pending_offer = insert(:announce, %{user_id: user_1.id, status: "PENDING", title: "bike"})
        messenger_params = messenger_params(messenger_id, "*999#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "Sorry mr_X, we cannot unlink your Messenger account because you still have 1 offers. \n\nFor help please send 0")
      # 17) Known user receives a msg after treating his pending offer
        IO.puts("test 17")
        # Find a way to test that
        get admin_conn, announce_path(admin_conn, :treat, %{announce_id: pending_offer.id, validate: true, cause: "ACCEPTED", category_id: pending_offer.category_id})
        # assert_sent_messenger_msg(messenger_id, "")
      # 18) Known user wants to receive list of his active offers and has offers
        IO.puts("test 18")
        insert_list(2, :announce, %{user_id: user_1.id, status: "ONLINE"})
        messenger_params = messenger_params(messenger_id, "*111#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", messenger_id, "Ok mr_X, you have 3 active offers :")
      # 19) Known user wants to quit messenger and confirms it
        IO.puts("test 19")
        offers = Contents.get_user_active_offers(user_1)
        for offer <- offers do
          Contents.update_announce(offer, %{status: "CLOSED"})
        end
        messenger_params = messenger_params(messenger_id, "*999#")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg("quit_bot", messenger_id, "Are you sure you want to remove Messenger link ?. If you are sure please type 1")
        messenger_params = messenger_params(messenger_id, "1")
        receive_messenger_msg(conn, messenger_id, messenger_params)
        assert_sent_messenger_msg(messenger_id, "Your Messenger account has been unlinked.\nHope to see you soon on https://www.pawchaungkaung.com")
        assert Members.get_active_user_by_bot_id(messenger_id, "messenger") == nil
      # 20) Another user takes his phone number, the history is kept in phone number history table
        IO.puts("test 20")
        # Starts a conversation
        receive_messenger_msg(conn, other_messenger_id, init_messenger_params(other_messenger_id))
        # Chooses his language
        messenger_params = messenger_params(other_messenger_id, "3")
        receive_messenger_msg(conn, other_messenger_id, messenger_params)
        # Selects his phone number
        messenger_params = messenger_params(other_messenger_id, "09110000003")
        receive_messenger_msg(conn, other_messenger_id, messenger_params)
        assert_sent_messenger_msg("no_scope", other_messenger_id, "Your phone number and Messenger account are now linked.\nPlease visit us on https://www.pawchaungkaung.com/offer/new/09110000003")
        user_2 = Members.get_active_user_by_bot_id(other_messenger_id, "messenger")
        # Check that the phone number history is kept for security
        # Members.list_phones() |> IO.inspect()
        old_phones = Members.get_phones_by_user_id(user_1.id)
        new_phone = Members.get_active_phone_by_user_id(user_2.id)
        assert Enum.count(old_phones) == 2
        for phone <- old_phones do
          assert phone.active == false
        end
        assert new_phone.active == true
    end
  end

end
