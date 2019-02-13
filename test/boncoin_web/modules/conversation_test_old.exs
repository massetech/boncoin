# defmodule BoncoinWeb.ConversationTest do
#   use BoncoinWeb.ConnCase
#   import Boncoin.{Factory}
#   import Boncoin.CustomModules.BotDecisions
#   alias BoncoinWeb.MessengerController
#   alias Boncoin.{Members, Contents, ViberApi, MessengerApi}
#   alias Boncoin.Auth.Guardian
#   import Mockery.Assertions
#   import Plug.Conn
#   use Mockery
#
#   @moduletag :ConversationModule
#   @moduletag :Module
#
#   defp init_messenger_params(messenger_id) do
#     %{"entry" => [%{"messaging" => [%{"postback" => %{"payload" => "GET_STARTED_PAYLOAD", "title" => nil},"sender" => %{"id" => messenger_id}}]}], "object" => "page"}
#   end
#   defp messenger_params(messenger_id, user_msg) do
#     %{"entry" => [%{"messaging" => [%{"sender" => %{"id" => messenger_id}, "message" => %{"text" => user_msg}}]}], "object" => "page"}
#   end
#   defp receive_messenger_msg(conn, messenger_id, messenger_params) do
#     case Members.get_active_user_by_bot_id(messenger_id, "messenger") do
#       nil ->
#         conn
#           |> assign(:current_user, nil) # To do the job of API plug
#           |> MessengerController.incoming_message(messenger_params)
#       user ->
#         conn
#           |> assign(:current_user, user) # To do the job of API plug
#           |> MessengerController.incoming_message(messenger_params)
#     end
#   end
#   defp assert_sent_answer_messenger_msg(scope, messenger_id, msg) do
#     conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
#     assert conversation.scope == scope
#     case msg do
#       "" -> assert_called MessengerApi, :send_message, ["RESPONSE", ^messenger_id, _msg, _quick_replies, _buttons, _offer] # Can't count the nb of calls in same test
#       msg -> assert_called MessengerApi, :send_message, ["RESPONSE", ^messenger_id, ^msg, _quick_replies, _buttons, _offer]
#     end
#   end
#
#   @tag :conversation_messenger
#   describe "Messenger conversation workflow" do
#     @describetag :member_authenticated
#     test "case 1", %{conn: conn} do
#       Mockery.History.enable_history()
#       admin_user = insert(:admin_user)
#       insert(:conversation, %{user_id: admin_user.id, bot_provider: "messenger"})
#       admin_conn = Phoenix.ConnTest.build_conn() |> Guardian.Plug.sign_in(admin_user, %{"typ" => "user-access"})
#       messenger_id = "messenger_1234"
#       other_messenger_id = "messenger_12345"
#       other_active_user = insert(:user, %{phone_number: "09110000001"})
#       insert(:conversation, %{user_id: other_active_user.id})
#       other_inactive_user = insert(:user, %{phone_number: "09110000003", active: false})
#       # 1) Unknown user opens conversation on Messenger
#         IO.puts("test 1")
#         receive_messenger_msg(conn, messenger_id, init_messenger_params(messenger_id))
#         assert_sent_answer_messenger_msg("language", messenger_id, "ေပါေခ်ာင္ေကာင္းမွႀကိဳဆိုပါတယ္။ ေက်းဇူးျပဳ၍သင္၏ဘာသာစကားကိုေ႐ြးခ်ယ္ပါ\n\nWelcome to Pawchaungkaung, please choose your language")
#       # 2) Unknown user selects a wrong language
#         IO.puts("test 2")
#         messenger_params = messenger_params(messenger_id, "uiczicb")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("language", messenger_id, "")
#       # 3) Unknown user selects language and receives question to phone number
#         IO.puts("test 3")
#         messenger_params = messenger_params(messenger_id, "3")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("visit_purpose", messenger_id, "Now we can speak !\nTo sell on Pawchaungkaung, you need to register your mobile phone number.")
#       # 3.2) Unknown user says he wants to register
#         IO.puts("test 3.2")
#         messenger_params = messenger_params(messenger_id, "1")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("link_phone", messenger_id, "Please type your Myanmar mobile phone number for the buyers to contact you.")
#       # 4) Unknown user types wrong phone number and receives 2nd question for phone number
#         IO.puts("test 4")
#         messenger_params = messenger_params(messenger_id, "090201020102")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("link_phone", messenger_id, "Sorry but you must provide a valid Myanmar phone number to register on Pawchaungkaung. Please type your mobile phone number for the buyers to contact you.")
#       # 5) Unknown user types wrong phone number 2nd time and receives welcome msg
#         IO.puts("test 5")
#         messenger_params = messenger_params(messenger_id, "08000000002")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("language", messenger_id, "")
#       # 6) Unknown user selects language and receives question to phone number
#         IO.puts("test 6")
#         messenger_params = messenger_params(messenger_id, "3")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("visit_purpose", messenger_id, "Now we can speak !\nTo sell on Pawchaungkaung, you need to register your mobile phone number.")
#       # 6.2) Unknown user says he wants to register
#         IO.puts("test 6.2")
#         messenger_params = messenger_params(messenger_id, "1")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("link_phone", messenger_id, "Please type your Myanmar mobile phone number for the buyers to contact you.")
#       # 7) Unknown user types already used phone number and receives question to phone number
#         IO.puts("test 7")
#         messenger_params = messenger_params(messenger_id, "09110000001")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("link_phone", messenger_id, "Sorry mr_X, this phone number is used by another user on viber. Please unlink it first or contact us.")
#       # 8) Unknown user types a free phone number and receives question to nickname
#         IO.puts("test 8")
#         messenger_params = messenger_params(messenger_id, "09110000002")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("nickname", messenger_id, "Your phone number and Messenger account are now linked.\nYour nickname is mr_X, please confirm or type a new nickname.")
#       # 8.2) Unknown user confirms his nickname and receives question to other language
#         IO.puts("test 8.2")
#         messenger_params = messenger_params(messenger_id, "1")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("other_language", messenger_id, "Do you speak another language ?")
#       # 8.3) Unknown user says he speaks burmese and receives question to viber_number
#         IO.puts("test 8.3")
#         messenger_params = messenger_params(messenger_id, "my")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         user_1 = Members.get_active_user_by_bot_id(messenger_id, "messenger")
#         assert user_1.other_language == "my"
#         assert_sent_answer_messenger_msg("viber_number", messenger_id, "If you want people to contact you on Viber please type your Myanmar Viber number now.")
#       # 9) Know user says nothing special
#         IO.puts("test 9")
#         messenger_params = messenger_params(messenger_id, "091234567")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "Thanks mr_X, you are now registered on Pawchaungkaung !\nYour phone number is 09110000002 and your Viber number is 091234567.\nPlease create your first offer !")
#       # 10) Known user wants to get help
#         IO.puts("test 10")
#         messenger_params = messenger_params(messenger_id, "0")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "We are ready to help mr_X")
#       # 11.1) Known user wants to change his language for MY and receives an alert
#         IO.puts("test 11")
#         messenger_params = messenger_params(messenger_id, "*123#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("language", messenger_id, "ေပါေခ်ာင္ေကာင္းမွႀကိဳဆိုပါတယ္။ ေက်းဇူးျပဳ၍သင္၏ဘာသာစကားကိုေ႐ြးခ်ယ္ပါ\n\nWelcome to Pawchaungkaung, please choose your language")
#       # 11.2) Known user confirms to change his language to MY
#         IO.puts("test 11.2")
#         messenger_params = messenger_params(messenger_id, "2")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         user_1 = Members.get_active_user_by_bot_id(messenger_id, "messenger")
#         conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
#         assert user_1.language == "my"
#         assert conversation.language == "my"
#         assert_sent_answer_messenger_msg("other_language_update", messenger_id, "အခြားဘာသာစကားပြောပါသလား")
#       # 11.3) Known user selects his other language to chinese
#         IO.puts("test 11.3")
#         messenger_params = messenger_params(messenger_id, "cn")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         user_1 = Members.get_active_user_by_bot_id(messenger_id, "messenger")
#         conversation = Members.get_conversation_by_provider_psid("messenger", messenger_id)
#         assert user_1.other_language == "cn"
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "")
#       # 12) Known user wants to change his phone number, types his own phone number and receives funny msg
#         # Come back to normal to continue the tests
#         Members.update_and_track_user(user_1, conversation, %{language: "en"})
#         Members.update_conversation(conversation, %{language: "en"})
#         IO.puts("Conversation reseted")
#         IO.puts("test 12")
#         messenger_params = messenger_params(messenger_id, "*888#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("update_phone", messenger_id, "All your offers will be moved to this new phone number. If you are sure please type your new phone number now.")
#         messenger_params = messenger_params(messenger_id, "09110000002")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "You know what mr_X, your phone number was already linked to this Messenger account :)")
#       # 13) Known user wants to change his phone number, types a number used by active user and receives alert msg
#         IO.puts("test 13")
#         messenger_params = messenger_params(messenger_id, "*888#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("update_phone", messenger_id, "")
#         messenger_params = messenger_params(messenger_id, "09110000001")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "Sorry mr_X, this phone number is used by another user on viber. Please unlink it first or contact us.")
#       # 14) Known user wants to change his phone number, types an old phone number and receives confirmation
#         IO.puts("test 14")
#         messenger_params = messenger_params(messenger_id, "*888#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("update_phone", messenger_id, "")
#         messenger_params = messenger_params(messenger_id, "09110000003")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "Perfect mr_X, your phone number was updated.")
#       # 15) Known user wants to receive list of his active offers but has no offer yet
#         IO.puts("test 15")
#         messenger_params = messenger_params(messenger_id, "*111#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "You don't have any active offer yet. Please create your first offer !")
#       # 16) Known user wants to quit messenger but has active offers
#         IO.puts("test 16")
#         pending_offer = insert(:announce, %{user_id: user_1.id, status: "PENDING", title: "bike"})
#         messenger_params = messenger_params(messenger_id, "*999#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "Sorry mr_X, we cannot close your Messenger account because you still have 1 offers.")
#       # 17) Known user receives a msg after treating his pending offer
#         IO.puts("test 17")
#         # Find a way to test that
#         get admin_conn, announce_path(admin_conn, :treat, %{announce_id: pending_offer.id, validate: true, cause: "ACCEPTED", category_id: pending_offer.category_id})
#         # assert_sent_answer_messenger_msg(messenger_id, "")
#       # 18) Known user wants to receive list of his active offers and has offers
#         IO.puts("test 18")
#         insert_list(2, :announce, %{user_id: user_1.id, status: "ONLINE"})
#         messenger_params = messenger_params(messenger_id, "*111#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", messenger_id, "Ok mr_X, you have 3 active offers.")
#       # 19) Known user wants to quit messenger and confirms it
#         IO.puts("test 19")
#         offers = Contents.get_user_active_offers(user_1)
#         for offer <- offers do
#           Contents.update_announce(offer, %{status: "CLOSED"})
#         end
#         messenger_params = messenger_params(messenger_id, "*999#")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("quit_bot", messenger_id, "Are you sure you want to quit Pawchaungkaung ? If you quit, you will need to register again to create new offer.")
#         IO.puts("test 19.2")
#         messenger_params = messenger_params(messenger_id, "1")
#         receive_messenger_msg(conn, messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("closed", messenger_id, "Your Messenger account has been closed.\nHope to see you soon on Pawchaungkaung !")
#         assert Members.get_active_user_by_bot_id(messenger_id, "messenger") == nil
#       # 20) Another user takes his phone number, the history is kept in phone number history table
#         IO.puts("test 20")
#         # Starts a conversation
#         receive_messenger_msg(conn, other_messenger_id, init_messenger_params(other_messenger_id))
#         # Chooses his language
#         messenger_params = messenger_params(other_messenger_id, "3")
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         # Confirms he wants to register
#         messenger_params = messenger_params(other_messenger_id, "1")
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         # Types his phone number
#         messenger_params = messenger_params(other_messenger_id, "09110000003")
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("nickname", other_messenger_id, "Your phone number and Messenger account are now linked.\nYour nickname is mr_X, please confirm or type a new nickname.")
#         # Finishes to register
#         messenger_params = messenger_params(other_messenger_id, "1") # Keeps nickname
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         messenger_params = messenger_params(other_messenger_id, "0") # No other language
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         messenger_params = messenger_params(other_messenger_id, "0") # Doenst use Viber number
#         receive_messenger_msg(conn, other_messenger_id, messenger_params)
#         assert_sent_answer_messenger_msg("no_scope", other_messenger_id, "Your phone number and Messenger account are now linked.\nYour nickname is mr_X, please confirm or type a new nickname.")
#
#         IO.puts("test 20.2")
#         user_2 = Members.get_active_user_by_bot_id(other_messenger_id, "messenger")
#         old_phones = Members.get_phones_by_user_id(user_1.id)
#         new_phone = Members.get_active_phone_by_user_id(user_2.id)
#         assert Enum.count(old_phones) == 2
#         for phone <- old_phones do
#           assert phone.active == false
#         end
#         assert new_phone.active == true
#     end
#   end
#
# end
