# defmodule BoncoinWeb.ViberConversationTest do
#   use BoncoinWeb.ConnCase
#   use Mockery
#   import Mockery.Assertions
#   import Plug.Conn
#   import Boncoin.{Factory}
#   alias BoncoinWeb.ViberController
#   alias Boncoin.Auth.Guardian
#   alias Boncoin.{Members, Contents, ViberApi}
#   alias Boncoin.CustomModules.BotDecisions
#
#   @moduletag :ViberConversationModule
#   @moduletag :Module
#
#   defp current_user_plug(viber_id) do
#     # Do the job of API plug
#     conn = Phoenix.ConnTest.build_conn()
#       |> Phoenix.Controller.put_view(BoncoinWeb.ViberView) # Needed for the first welcome msg in json response
#     case Members.get_active_user_by_bot_id(viber_id, "viber") do
#       nil ->
#         conn
#           |> assign(:current_user, nil)
#       user ->
#         conn
#           |> assign(:current_user, user)
#     end
#   end
#
#   defp receive_conversation_started_with_context(viber_id, viber_name, context) do
#     conn = current_user_plug(viber_id)
#     ViberController.callback(conn, %{"event" => "conversation_started", "context" => context, "user" => %{"id" => viber_id, "name" => viber_name}})
#   end
#   defp receive_conversation_started_without_context(viber_id, viber_name) do
#     conn = current_user_plug(viber_id)
#     ViberController.callback(conn, %{"event" => "conversation_started", "user" => %{"id" => viber_id, "name" => viber_name}})
#   end
#   defp receive_msg(viber_id, viber_name, user_msg) do
#     viber_params = %{"event" => "message", "timestamp" => "time_now", "sender" => %{"id" => viber_id, "name" => viber_name}, "message" => %{"type" => "text", "text" => user_msg}}
#     conn = current_user_plug(viber_id)
#     ViberController.callback(conn, viber_params)
#   end
#
#   defp assert_welcome_msg_answered(conn, scope, viber_id) do
#     conversation = Members.get_conversation_by_provider_psid("viber", viber_id)
#     assert conversation.scope == scope
#     assert conn.resp_body =~ "Welcome to Pawchaungkaung, please choose your language"
#   end
#   defp assert_msg_answered(scope, viber_id, msg) do
#     conversation = Members.get_conversation_by_provider_psid("viber", viber_id)
#     unless scope == :update, do: assert conversation.scope == scope
#     type = if scope == :update, do: :update, else: nil
#     case msg do
#       "" -> assert_called ViberApi, :send_message, [^type, ^viber_id, _msg, _quick_replies, _buttons, _offer] # Can't count the nb of calls in same test
#       msg -> assert_called ViberApi, :send_message, [^type, ^viber_id, ^msg, _quick_replies, _buttons, _offer]
#     end
#   end
#   defp assert_admin_informed(admin_user, msg) do
#     admin_psid = admin_user.conversation.psid
#     assert_called ViberApi, :send_message, [nil, ^admin_psid, ^msg, _quick_replies, _buttons, _offer]
#   end
#
#   describe "Viber conversation workflow" do
#     @tag :ViberRegistration
#     test "user registration" do
#       Mockery.History.enable_history()
#       # Initiate admin
#       admin_user = insert(:admin_user)
#       insert(:conversation, %{user_id: admin_user.id, bot_provider: "viber", psid: "hPAtCbK9yIaDQumAoQ50sQ=="})
#       admin_user = Members.get_user(admin_user.id) # Preload conversation
#       context = "#{admin_user.id}"
#       # Initiate visitor
#       viber_id = "viber_1234"
#       viber_name = "Mr viber 1234"
#       phone_number = "09110000002"
#       # Initiate other user
#       other_viber_id = "other_viber_id"
#       other_user = insert(:user, %{phone_number: "09110000001"})
#       insert(:conversation, %{user_id: other_user.id, psid: other_viber_id})
#       other_user = Members.get_user(other_user.id) # Preload conversation
#
#       # 1.1) Unknown user opens conversation with context
#         IO.puts("test 1.1")
#         result = receive_conversation_started_with_context(viber_id, viber_name, context)
#         assert_welcome_msg_answered(result, "language", viber_id)
#       # 1.2) Unknown user opens conversation without context
#         IO.puts("test 1.2")
#         result = receive_conversation_started_without_context(viber_id, viber_name)
#         assert_welcome_msg_answered(result, "language", viber_id)
#       # 2) Unknown user selects a wrong language
#         IO.puts("test 2")
#         receive_msg(viber_id, viber_name, "wrong_language")
#         assert_msg_answered("language", viber_id, BotDecisions.welcome_msg())
#       # 3) Unknown user selects his language
#         IO.puts("test 3")
#         receive_msg(viber_id, viber_name, "3")
#         assert_msg_answered("visit_purpose", viber_id, BotDecisions.ask_visit_purpose_msg("en"))
#       # 4) Unknown user says he wants to register
#         IO.puts("test 3")
#         receive_msg(viber_id, viber_name, "1")
#         assert_msg_answered("link_phone", viber_id, BotDecisions.ask_phone_msg("en"))
#       # 5.1) Unknown user types wrong phone number
#         IO.puts("test 5.1")
#         receive_msg(viber_id, viber_name, "wrong_phone_number")
#         assert_msg_answered("link_phone", viber_id, BotDecisions.ask_again_phone_msg("en"))
#       # 5.2) Unknown user types wrong phone number 2nd time and receives welcome msg
#         IO.puts("test 5.2")
#         receive_msg(viber_id, viber_name, "wrong_phone_number")
#         assert_msg_answered("language", viber_id, BotDecisions.welcome_msg())
#       # 6) Unknown user selects language and already used phone number
#         IO.puts("test 6")
#         receive_msg(viber_id, viber_name, "3")
#         receive_msg(viber_id, viber_name, "1")
#         receive_msg(viber_id, viber_name, other_user.phone_number)
#         conversation = Members.get_conversation_by_provider_psid("viber", viber_id)
#         assert_msg_answered("link_phone", viber_id, BotDecisions.announce_bot_conflict(conversation, other_user))
#       # 7) User types a free phone number : user is created
#         IO.puts("test 7")
#         receive_msg(viber_id, viber_name, phone_number)
#         user = Members.get_active_user_by_bot_id(viber_id, "viber")
#         assert user.conversation.origin == context
#         assert_msg_answered("nickname", viber_id, BotDecisions.ask_nickname_msg(user, user.conversation))
#         assert_admin_informed(admin_user, Members.new_user_msg(user))
#       # 8) User confirms his nickname
#         IO.puts("test 8")
#         receive_msg(viber_id, viber_name, "1")
#         assert_msg_answered("other_language", viber_id, BotDecisions.ask_other_language("en"))
#       # 9) User says he speaks also burmese
#         IO.puts("test 9")
#         receive_msg(viber_id, viber_name, "my")
#         assert_msg_answered("viber_number", viber_id, BotDecisions.ask_viber_number("en"))
#         user_1 = Members.get_active_user_by_bot_id(viber_id, "viber")
#         assert user_1.other_language == "my"
#       # 10) User gives his Viber number
#         IO.puts("test 10")
#         receive_msg(viber_id, viber_name, "091234567")
#         user = Members.get_active_user_by_bot_id(viber_id, "viber")
#         assert_msg_answered("no_scope", viber_id, BotDecisions.welcome_new_user(user))
#         assert user.viber_number == "091234567"
#     end
#
#     @tag :ViberConversation
#     test "user conversation" do
#       Mockery.History.enable_history()
#       # Initiate admin
#       admin_user = insert(:admin_user)
#       insert(:conversation, %{user_id: admin_user.id, bot_provider: "viber", psid: "hPAtCbK9yIaDQumAoQ50sQ=="})
#       admin_user = Members.get_user(admin_user.id) # Preload conversation
#       context = "#{admin_user.id}"
#       # Initiate user
#       user = insert(:user, %{phone_number: "09110000012", nickname: "Mr viber 3456", language: "en", other_language: "jp"})
#       insert(:conversation, %{user_id: user.id, bot_provider: "viber", nickname: "Mr viber 3456", psid: "viber_3456", scope: "no_scope", origin: context})
#       user = Members.get_user(user.id) # Preload conversation
#       viber_id = user.conversation.psid
#       viber_name = user.conversation.nickname
#       # Initiate other user
#       other_user = insert(:user, %{phone_number: "09110000013"})
#       insert(:conversation, %{user_id: other_user.id, psid: "other_viber_id"})
#       other_user = Members.get_user(other_user.id) # Preload conversation
#       # Initiate other user 2
#       other_user_2 = insert(:user, %{phone_number: "09110000014", active: false})
#       insert(:conversation, %{user_id: other_user_2.id, psid: "other_viber_2_id", active: false})
#       other_user_2 = Members.get_user(other_user_2.id) # Preload conversation
#       # Other params
#       free_phone_number = "09110000020"
#
#       # 21) User says nothing special
#         IO.puts("test 21")
#         receive_msg(viber_id, viber_name, "blabla")
#         assert_msg_answered("no_scope", viber_id, "")
#       # 22) User wants to get help
#         IO.puts("test 22")
#         receive_msg(viber_id, viber_name, "0")
#         assert_msg_answered("no_scope", viber_id, BotDecisions.inform_help(user))
#       # 23.1) User wants to change his language
#         IO.puts("test 23.1")
#         receive_msg(viber_id, viber_name, "*123#")
#         assert_msg_answered("language", viber_id, BotDecisions.change_language_msg())
#       # 23.2) User changes his language to MY
#         IO.puts("test 23.2")
#         receive_msg(viber_id, viber_name, "2")
#         user = Members.get_user(user.id)
#         assert user.language == "my"
#         assert user.conversation.language == "my"
#         assert_msg_answered("other_language_update", viber_id, BotDecisions.ask_other_language("my"))
#       # 23.3) User selects his other language to chinese
#         IO.puts("test 23.3")
#         receive_msg(viber_id, viber_name, "cn")
#         user = Members.get_user(user.id)
#         assert user.other_language == "cn"
#         assert_msg_answered("no_scope", viber_id, "")
#       # 24.1) User wants to change his phone number and types his own phone number
#         IO.puts("test 24.1")
#         receive_msg(viber_id, viber_name, "*888#")
#         assert_msg_answered("update_phone", viber_id, BotDecisions.alert_before_phone_update(user))
#         receive_msg(viber_id, viber_name, user.phone_number)
#         assert_msg_answered("no_scope", viber_id, BotDecisions.tell_same_phone_number(user))
#       # 24.2) User wants to change his phone number ant types a phone number already used
#         IO.puts("test 24.2")
#         receive_msg(viber_id, viber_name, "*888#")
#         receive_msg(viber_id, viber_name, other_user.phone_number)
#         assert_msg_answered("no_scope", viber_id, BotDecisions.announce_bot_conflict(user.conversation, other_user))
#       # 24.3) User wants to change his phone number ant types a an old inactive phone number
#         IO.puts("test 24.3")
#         receive_msg(viber_id, viber_name, "*888#")
#         receive_msg(viber_id, viber_name, other_user_2.phone_number)
#         user = Members.get_user(user.id)
#         assert user.phone_number == other_user_2.phone_number
#         assert_msg_answered("no_scope", viber_id, BotDecisions.confirm_new_phone_number_updated(user))
#       # 24.4) User wants to change his phone number ant types a phone number which is free
#         IO.puts("test 24.4")
#         receive_msg(viber_id, viber_name, "*888#")
#         receive_msg(viber_id, viber_name, free_phone_number)
#         user = Members.get_user(user.id)
#         assert user.phone_number == free_phone_number
#         assert_msg_answered("no_scope", viber_id, BotDecisions.confirm_new_phone_number_updated(user))
#       # 25.1) User wants to receive list of his active offers but has no offer yet
#         IO.puts("test 25.1")
#         receive_msg(viber_id, viber_name, "*111#")
#         assert_msg_answered("no_scope", viber_id, BotDecisions.tell_no_active_offer(user))
#       # 25.2) User wants to receive list of his active offers and has offers
#         IO.puts("test 25.2")
#         insert_list(2, :announce, %{user_id: user.id, status: "ONLINE"})
#         receive_msg(viber_id, viber_name, "*111#")
#         assert_msg_answered("no_scope", viber_id, BotDecisions.tell_nb_active_offers(user, 2))
#       # 26) User wants to quit messenger but has active offers
#         IO.puts("test 26")
#         pending_offer = insert(:announce, %{user_id: user.id, status: "PENDING", title: "bike"})
#         receive_msg(viber_id, viber_name, "*999#")
#         assert_msg_answered("no_scope", viber_id, BotDecisions.tell_not_allowed_to_quit_bot(user, 3))
#       # 27.1) Known user receives a msg after treating his pending offer
#         IO.puts("test 27.1")
#         Contents.treat_announce(admin_user, %{"announce_id" => pending_offer.id, "validate" => "true", "cause" => "ACCEPTED", "category_id" => pending_offer.category_id})
#         accepted_offer = Contents.get_announce!(pending_offer.id)
#         assert_msg_answered(:update, viber_id, BotDecisions.tell_offer_accepted(user, accepted_offer))
#       # 27.2) Known user posting offer is counted in embassadors KPI
#         IO.puts("test 27.2")
#         filter = %{month: Kernel.inspect(Timex.now().month), year: Kernel.inspect(Timex.now().year)}
#         embassador_kpi = Members.get_embassador_kpi("#{admin_user.id}", filter)
#         assert embassador_kpi == %{nb_new_publishers: 1, nb_new_users: 1, nb_publishers: 1, nb_user: 1}
#       # 28) User wants to quit and confirms it
#         IO.puts("test 28")
#         offers = Contents.get_user_active_offers(user)
#         for offer <- offers do
#           Contents.update_announce(offer, %{status: "CLOSED"})
#         end
#         receive_msg(viber_id, viber_name, "*999#")
#         assert_msg_answered("quit_bot", viber_id, BotDecisions.alert_before_quit_bot(user))
#         receive_msg(viber_id, viber_name, "1")
#         assert Members.get_active_user_by_bot_id(viber_id, "viber") == nil
#         assert_msg_answered("closed", viber_id, BotDecisions.tell_bot_quitted(user))
#       # 28.1) Another user takes this phone number
#         IO.puts("test 28.1")
#         receive_msg(other_user.conversation.psid, other_user.conversation.nickname, "*888#")
#         receive_msg(other_user.conversation.psid, other_user.conversation.nickname, free_phone_number)
#         other_user = Members.get_user(other_user.id)
#         assert other_user.phone_number == free_phone_number
#         assert_msg_answered("no_scope", other_user.conversation.psid, BotDecisions.confirm_new_phone_number_updated(other_user))
#         # 28.2) The history of 2 users is kept
#           IO.puts("test 28.2")
#           old_phones = Members.get_phones_by_user_id(user.id)
#           assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000012" end) != nil
#           assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000014" end) != nil
#           assert Enum.find(old_phones, fn phone -> phone.phone_number == "09110000020" end) != nil
#     end
#   end
#
# end
