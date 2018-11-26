defmodule BoncoinWeb.BotTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory
  import Boncoin.CustomModules.BotDecisions

  @moduletag :BotModule
  @moduletag :Module

  describe "bot algorythm scope welcome" do
    test "with unknown user", %{conn: conn} do
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: %{scope: nil}, announce: nil, user_msg: nil}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
    test "with known user", %{conn: conn} do
      user = insert(:user)
      conversation = insert(:conversation, %{psid: "viber_0"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: conversation, announce: nil, user_msg: nil}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Welcome back to Pawchaungkaung Mr unknown"
    end
  end

  describe "bot algorythm scope language" do
    test "with unknown user ask language again", %{conn: conn} do
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: %{scope: nil}, announce: nil, user_msg: "blablabla"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
    test "with unknown user scope language ask phone", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: %{scope: "language"}, announce: nil, user_msg: "3"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Now we can speak!"
    end
    test "with know user update language and say nothing", %{conn: conn} do
      user = insert(:user, %{language: "dz"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "language"}, announce: nil, user_msg: "3"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Please visit us on http://localhost:4001"
    end
  end

  describe "bot algorythm scope link_phone for new user" do
    test "confirm user creation", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone_1", psid: "viber_1"})
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09020202020"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Your phone number and Viber account are now linked"
    end
    test "ask phone again", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone_1", psid: "viber_2"})
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: conversation, announce: nil, user_msg: "blablabla"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Sorry but we need to identify you"
    end
    test "phone conflict with active other user is refused", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone_1", psid: "viber_3"})
      other_user = insert(:user, %{bot_active: true, bot_id: "123", phone_number: "09010101010"})
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101010"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "this phone number is used by another user"
    end
    test "phone conflict with old other user is accepted", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone_1", psid: "viber_4"})
      other_user = insert(:user, %{active: false, bot_active: false, bot_id: "dededde", bot_provider: "messenger", phone_number: "09010101017"})
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101017"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account are now linked.\nPlease visit us on"
    end
    test "phone conflict with same user comming back is accepted", %{conn: conn} do
      conversation = insert(:conversation, %{scope: "link_phone_1", psid: "12345"})
      other_user = insert(:user, %{bot_active: false, bot_id: "12345", bot_provider: "viber", phone_number: "09010101333"})
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: conversation, announce: nil, user_msg: "09010101333"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "you get back your phone number"
    end
  end

  describe "bot algorythm scope offer_treated" do
    test "confirm offer accepted", %{conn: conn} do
      user = insert(:user)
      announce = insert(:announce, %{status: "ONLINE", user_id: user.id})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "offer_treated"}, announce: announce, user_msg: nil}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "your offer an offer title is now published !"
    end
    test "announce offer refused", %{conn: conn} do
      user = insert(:user)
      announce = insert(:announce, %{status: "REFUSED", cause: "Description not clear", user_id: user.id})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "offer_treated"}, announce: announce, user_msg: nil}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "we are sorry but your offer an offer title was refused"
    end
  end

  describe "bot algorythm scope changing language" do
    test "for know user", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*123#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Please choose your language"
    end
  end

  describe "bot algorythm scope listing offfers" do
    test "announce 0 offer online", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*111#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "You don't have any offer yet"
    end
    test "announce 3 offers online", %{conn: conn} do
      user = insert(:user)
      insert_list(3, :announce, %{status: "ONLINE", user_id: user.id})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*111#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "you have 3 active offers :"
    end
  end

  describe "bot algorythm scope update phone number" do
    test "explain to user", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*888#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "All your offers will be moved to this new phone number"
    end
    test "announce same phone number was given", %{conn: conn} do
      user = insert(:user, %{phone_number: "09030303030"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: user.phone_number}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "your phone number was already linked to this Viber account :)"
    end
    test "confirm phone number updated", %{conn: conn} do
      user = insert(:user, %{phone_number: "09030303030"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: "09030303032"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "your phone number was updated"
    end
    test "alert wrong phone number", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: "0902020202029282"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "this is not a good phone number"
    end
    test "phone conflict with bot is refused", %{conn: conn} do
      user = insert(:user, %{bot_active: true, bot_id: "12345", phone_number: "09020202020"})
      other_user = insert(:user, %{bot_active: true, bot_id: "123", phone_number: "09010101010"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: "09010101010"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "this phone number is used by another user"
    end
    test "phone conflict without offer is accepted", %{conn: conn} do
      user = insert(:user, %{bot_active: true, bot_id: "12345", phone_number: "09020202020"})
      other_user = insert(:user, %{bot_active: false, bot_id: "54321", phone_number: "09010101019"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: "09010101019"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "your phone number was updated"
    end
    test "phone conflict with offer is refused", %{conn: conn} do
      user = insert(:user, %{bot_active: true, bot_id: "12345", phone_number: "09020202020"})
      other_user = insert(:user, %{bot_active: false, bot_id: "54321", phone_number: "09010101019"})
      insert_list(3, :announce, %{user_id: other_user.id})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "update_phone"}, announce: nil, user_msg: "09010101019"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "this phone number is used by another user"
    end
  end

  describe "bot algorythm scope quit viber" do
    test "user asks to quit and has no active announce", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Are you sure you want to remove Viber link ?"
    end
    test "user asks to quit but has PENDING announces", %{conn: conn} do
      user = insert(:user)
      insert_list(3, :announce, %{user_id: user.id, status: "PENDING"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account because you still have 3 offers"
    end
    test "user asks to quit but has ONLINE announces", %{conn: conn} do
      user = insert(:user)
      insert_list(2, :announce, %{user_id: user.id, treated_by_id: user.id, status: "ONLINE"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account because you still have 2 offers"
    end
    test "user asks to quit but has ONLINE and PENDING announces", %{conn: conn} do
      user = insert(:user)
      insert_list(3, :announce, %{user_id: user.id, status: "PENDING"})
      insert_list(2, :announce, %{user_id: user.id, treated_by_id: user.id, status: "ONLINE"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account because you still have 5 offers"
    end
    test "user confirms to quit with 1", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "quit_bot"}, announce: nil, user_msg: "1"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account has been unlinked"
    end
    test "user confirms to quit by wrong entry", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "quit_bot"}, announce: nil, user_msg: "other thing"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Please visit us on"
    end
    test "user confirms to quit but has active offers", %{conn: conn} do
      user = insert(:user)
      insert_list(3, :announce, %{user_id: user.id})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: "quit_bot"}, announce: nil, user_msg: "*999#"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "account because you still have 3 offers"
    end
  end

  describe "bot algorythm" do
    test "display help", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "0"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "We are happy to help"
    end
  end

  describe "bot algorythm nothing to say (fallback)" do
    test "user known in EN", %{conn: conn} do
      user = insert(:user)
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Please visit us on"
    end
    test "user known in MY", %{conn: conn} do
      user = insert(:user, %{language: "my"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "ကျေးဇူးပြု၍"
    end
    test "user known in DZ", %{conn: conn} do
      user = insert(:user, %{language: "dz"})
      %{scope: scope, language: language, messages: messages} = %{user: user, conversation: %{scope: ""}, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "ေက်းဇူးျပဳ၍"
    end
    test "user unknown", %{conn: conn} do
      %{scope: scope, language: language, messages: messages} = %{user: nil, conversation: %{scope: ""}, announce: nil, user_msg: "whatever anything"}
        |> call_bot_algorythm()
      msg = List.first(messages)
      assert msg =~ "Welcome to Pawchaungkaung, please choose your language"
    end
  end

end
