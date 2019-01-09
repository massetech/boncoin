defmodule BoncoinWeb.BotTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory
  import Boncoin.CustomModules.BotDecisions
  alias Boncoin.{Members}

  @moduletag :BotModule
  @moduletag :Module

  describe "bot algorythm scope welcome" do
    test "with unknown user", %{conn: conn} do
      %{messages: %{message: msg}} = %{user: nil, conversation: %{scope: "welcome", bot_provider: "viber"}, announce: nil, user_msg: nil}
        |> call_bot_algorythm()
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
    test "with known user", %{conn: conn} do
      user = insert(:user, %{active: false})
      conversation = insert(:conversation, %{psid: "viber_0", active: false})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: nil}
        |> call_bot_algorythm()
      assert msg =~ "Welcome back to Pawchaungkaung Mr unknown"
    end
  end

  describe "bot algorythm scope language" do
    test "with unknown user ask language again", %{conn: conn} do
      %{messages: %{message: msg}} = %{user: nil, conversation: %{scope: "welcome", bot_provider: "viber"}, announce: nil, user_msg: "blablabla"}
        |> call_bot_algorythm()
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
    test "with unknown user scope language ask phone", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{user_id: user.id, scope: "language"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "3"}
        |> call_bot_algorythm()
      assert msg =~ "Now we can speak !\nTo sell on Pawchaungkaung, you need to register"
    end
    test "with know user update language and ask if other language", %{conn: conn} do
      user = insert(:user, %{language: "dz"})
      conversation = insert(:conversation, %{user_id: user.id, scope: "language", language: "dz"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "3"}
        |> call_bot_algorythm()
      assert msg =~ "Do you speak another language ?"
    end
    test "with know user update other language says nothing", %{conn: conn} do
      user = insert(:user, %{language: "dz"})
      conversation = insert(:conversation, %{user_id: user.id, scope: "other_language_update", language: "dz"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "3"}
        |> call_bot_algorythm()
      assert msg =~ "Mr unknown"
    end
  end

  describe "bot algorythm scope link_phone for new user" do
    test "confirm user creation", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone", psid: "viber_1"})
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09020202020"}
        |> call_bot_algorythm()
      assert msg =~ "Your phone number and Viber account are now linked"
    end
    test "ask phone again", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone", psid: "viber_2"})
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "blablabla"}
        |> call_bot_algorythm()
      assert msg =~ "Sorry but you must provide a valid Myanmar phone number"
    end
    test "phone conflict with active other user is refused", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone", psid: "viber_3"})
      other_user = insert(:user, %{phone_number: "09010101010"})
      insert(:conversation, %{active: true, psid: "123", user_id: other_user.id})
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101010"}
        |> call_bot_algorythm()
      assert msg =~ "this phone number is used by another user"
    end
    test "phone conflict with old other user is accepted", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone", psid: "viber_4"})
      user = insert(:user, %{active: false, phone_number: "09010101017"})
      insert(:conversation, %{active: false, psid: "dededde", user_id: user.id, bot_provider: "messenger"})
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101017"}
        |> call_bot_algorythm()
      assert msg =~ "account are now linked.\nYour nickname"
    end
    test "phone conflict with same user comming back is accepted", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone", psid: "12345"})
      other_user = insert(:user, %{phone_number: "09010101333"})
      insert(:conversation, %{active: false, psid: "12345", user_id: other_user.id})
      %{messages: %{message: msg}} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101333"}
        |> call_bot_algorythm()
      assert msg =~ "you get back your phone number"
    end
  end

  describe "bot algorythm scope offer_treated" do
    test "confirm offer accepted", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "offer_treated", user_id: user.id})
      announce = insert(:announce, %{status: "ONLINE", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: announce, user_msg: nil}
        |> call_bot_algorythm()
      assert msg =~ "your offer is now published"
    end
    test "announce offer refused", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "offer_treated", user_id: user.id})
      announce = insert(:announce, %{status: "REFUSED", cause: "Description not clear", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: announce, user_msg: nil}
        |> call_bot_algorythm()
      assert msg =~ "we are sorry but your offer was refused because"
    end
  end

  describe "bot algorythm scope changing language" do
    test "for know user", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "language", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*123#"}
        |> call_bot_algorythm()
      assert msg =~ "Please choose your language"
    end
  end

  describe "bot algorythm scope listing offfers" do
    test "announce 0 offer online", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*111#"}
        |> call_bot_algorythm()
      assert msg =~ "You don't have any active offer yet"
    end
    test "announce 3 offers online", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id})
      insert_list(3, :announce, %{status: "ONLINE", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*111#"}
        |> call_bot_algorythm()
      assert msg =~ "you have 3 active offers"
    end
  end

  describe "bot algorythm scope update phone number" do
    test "explain to user", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*888#"}
        |> call_bot_algorythm()
      assert msg =~ "All your offers will be moved to this new phone number"
    end
    test "announce same phone number was given", %{conn: conn} do
      user = insert(:user, %{phone_number: "09030303030"})
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: user.phone_number}
        |> call_bot_algorythm()
      assert msg =~ "your phone number was already linked to this Viber account :)"
    end
    test "confirm phone number updated", %{conn: conn} do
      user = insert(:user, %{phone_number: "09030303030"})
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "09030303032"}
        |> call_bot_algorythm()
      assert msg =~ "your phone number was updated"
    end
    test "alert wrong phone number", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "0902020202029282"}
        |> call_bot_algorythm()
      assert msg =~ "this is not a good phone number"
    end
    test "phone conflict with bot is refused", %{conn: conn} do
      user = insert(:user, %{phone_number: "09020202020"})
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id, psid: "12345"})
      other_user = insert(:user, %{phone_number: "09010101010"})
      insert(:conversation, %{scope: "update_phone", user_id: other_user.id, psid: "123"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "09010101010"}
        |> call_bot_algorythm()
      assert msg =~ "this phone number is used by another user"
    end
    test "phone conflict without offer is accepted", %{conn: conn} do
      user = insert(:user, %{phone_number: "09020202020"})
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id, psid: "12345"})
      other_user = insert(:user, %{active: false, phone_number: "09010101019"})
      insert(:conversation, %{active: false, scope: "update_phone", user_id: other_user.id, psid: "54321"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "09010101019"}
        |> call_bot_algorythm()
      assert msg =~ "your phone number was updated"
    end
    test "phone conflict with offer is refused", %{conn: conn} do
      user = insert(:user, %{phone_number: "09020202020"})
      conversation = insert(:conversation, %{scope: "update_phone", user_id: user.id, psid: "12345"})
      other_user = insert(:user, %{phone_number: "09010101019"})
      insert(:conversation, %{active: true, scope: "update_phone", user_id: other_user.id, psid: "54321"})
      insert_list(3, :announce, %{user_id: other_user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "09010101019"}
        |> call_bot_algorythm()
      assert msg =~ "this phone number is used by another user"
    end
  end

  describe "bot algorythm scope quit viber" do
    test "user asks to quit and has no active announce", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      assert msg =~ "Are you sure you want to quit Pawchaungkaung ?"
    end
    test "user asks to quit but has PENDING announces", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      insert_list(3, :announce, %{user_id: user.id, status: "PENDING"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      assert msg =~ "account because you still have 3 offers"
    end
    test "user asks to quit but has ONLINE announces", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      insert_list(2, :announce, %{user_id: user.id, treated_by_id: user.id, status: "ONLINE"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      assert msg =~ "account because you still have 2 offers"
    end
    test "user asks to quit but has ONLINE and PENDING announces", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      insert_list(3, :announce, %{user_id: user.id, status: "PENDING"})
      insert_list(2, :announce, %{user_id: user.id, treated_by_id: user.id, status: "ONLINE"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      assert msg =~ "account because you still have 5 offers"
    end
    test "user confirms to quit with 1", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "1"}
        |> call_bot_algorythm()
      assert msg =~ "Your Viber account has been closed.\nHope to see you soon on Pawchaungkaung"
    end
    test "user confirms to quit by wrong entry", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "other thing"}
        |> call_bot_algorythm()
      assert msg =~ "Hi Mr unknown !"
    end
    test "user confirms to quit but has active offers", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "quit_bot", user_id: user.id, psid: "12345"})
      insert_list(3, :announce, %{user_id: user.id})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      assert msg =~ "account because you still have 3 offers"
    end
  end

  describe "bot algorythm" do
    test "display help", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "0"}
        |> call_bot_algorythm()
      assert msg =~ "We are ready to help"
    end
  end

  describe "bot algorythm nothing to say (fallback)" do
    test "user known in EN", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      assert msg =~ "Hi Mr unknown !"
    end
    test "user known in MY", %{conn: conn} do
      user = insert(:user, %{language: "my"})
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      assert msg =~ "မင်္ဂလာပါ Mr unknown။"
    end
    test "user known in DZ", %{conn: conn} do
      user = insert(:user, %{language: "dz"})
      conversation = insert(:conversation, %{scope: "no_scope", user_id: user.id, psid: "12345"})
      user = Members.get_user(user.id)
      %{messages: %{message: msg}} = %{user: user, conversation: conversation, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      assert msg =~ "မဂၤလာပါ Mr unknown။"
    end
    test "user unknown", %{conn: conn} do
      %{messages: %{message: msg}} = %{user: nil, conversation: %{scope: "welcome", bot_provider: "viber"}, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
  end

end
