# defmodule Boncoin.ViberApi do
#   use BoncoinWeb, :controller # Added for test functions only
#   alias Boncoin.{Members, Contents} # Added for test functions only
#   alias Boncoin.CustomModules.BotDecisions # Added for test functions only
#   @api_url "https://chatapi.viber.com/pa/"
#
#   # //// MANUAL TESTS OF VIBER BOT .....
#     # def test_viber_new_conversation() do
#     # end
#   # Test manually the user sending a msg (nil message not possible)
#   def test_viber_new_message(user_id, conversation_scope, user_msg) do
#     conversation = Members.get_conversation_by_user_id(user_id)
#     Members.update_conversation(conversation, %{scope: conversation_scope})
#       |> IO.inspect()
#     user = Members.get_user(user_id)
#     params = %{"event" => "message", "timestamp" => "time for lunch", "sender" => %{"id" => user.conversation.psid, "name" => user.nickname}, "message" => %{"type" => "text", "text" => user_msg}}
#     conn = %Plug.Conn{private: %{phoenix_endpoint: BoncoinWeb.Endpoint}}
#       |> assign(:current_user, user)
#     BoncoinWeb.ViberController.callback(conn, params)
#     # We end up with Plug.MissingAdapter.send_resp/4 is undefined since the conn is not proper
#   end
#   # Test manually the user receiving his offer published
#   def test_viber_offer_published(user_id, offer_id) do
#     user = Members.get_user(user_id)
#     offer = Contents.get_announce!(offer_id)
#     %{user: user, conversation: Map.put(user.conversation, :scope, "offer_treated"), announce: offer, user_msg: ""}
#       |> BotDecisions.call_bot_algorythm()
#       |> Members.send_bot_message_to_user(offer, :update)
#     # We end up with the bot results of Members.send_bot_message_to_user
#   end
#
#   # --------------------------------------------------------------------------
#
#   # API doc https://developers.viber.com/docs/api/rest-bot-api/#general-send-message-parameters
#   # More docs https://developers.viber.com/docs/all/
#   def send_message(type, psid, msg, quick_replies, buttons, offer) do
#     # Using Viber keyboards : https://developers.viber.com/docs/tools/keyboards/
#     # Rich media requires min_api_version 2
#     # type is not used in Viber (needed in Messenger only)
#     # IO.inspect(buttons)
#     # IO.inspect(offer)
#
#     msg_params = cond do
#       buttons == [] && offer == nil -> # No buttons and no offer : send a simple text message
#         %{receiver: psid, type: "text", text: msg, keyboard: build_keyboard(quick_replies)}
#       true -> # Send a rich_media message
#         %{receiver: psid, min_api_version: 2, type: "rich_media", rich_media: build_rich_media(offer, msg, buttons), keyboard: build_keyboard(quick_replies)}
#     end
#
#     # Function results are not used after : alert in case of problem
#     case post(msg_params, "send_message") do
#       {:ok, msg} -> {:ok, msg}
#       {:error, msg} ->
#         IO.inspect(msg)
#         {:error, msg}
#     end
#   end
#
#   def check_online() do
#     IO.puts("Webhook Viber tested at #{Timex.now()}")
#     case post(%{ids: ["01234567890="]}, "get_online") do
#       {:ok, _resp} -> "online"
#       {:error, resp} ->
#         IO.puts("Problems on Viber Webhook not answering")
#         IO.inspect(resp)
#         "offline"
#     end
#   end
#
#   def post(payload \\ %{}, path) do
#     # IO.puts("Viber post params")
#     # IO.inspect(payload)
#     token = get_viber_token()
#     uri = URI.merge(@api_url, path) |> to_string
#     resp = HTTPoison.post uri, Jason.encode!(payload), prepare_headers(token)
#     case resp do
#       {:ok, response} ->
#         response.body
#           |> Jason.decode
#           |> handle_response
#       {:error, msg} ->
#         IO.puts("The request was not posted to Viber (Elixir internal problem)")
#         IO.inspect(msg)
#         {:error, msg}
#     end
#   end
#
#   defp get_viber_token() do
#     Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:viber_secret]
#   end
#
#   defp prepare_headers(access_token) do
#     ["Content-Type": "application/json", "X-Viber-Auth-Token": access_token]
#   end
#
#   defp handle_response({:ok, resp}), do: if resp["status"] > 0, do: {:error, resp}, else: {:ok, resp}
#   defp handle_response(_), do: {:error, "Unexpected response from Viber"}
#
#   defp build_keyboard(quick_replies) do
#     case quick_replies do
#       [] -> nil
#       _ ->
#         %{
#           Type: "keyboard",
#           DefaultHeight: false,
#           BgColor: "#ffffff", # Yellow #ffec00
#           Buttons: build_quick_replies(quick_replies)
#         }
#     end
#   end
#   defp build_quick_replies(quick_replies) do
#     nb_col = cond do
#       Kernel.length(quick_replies) == 1 -> 6
#       Kernel.length(quick_replies) == 2 -> 3
#       true -> 2
#     end
#     Enum.map(quick_replies, fn quick_reply -> build_quick_reply(quick_reply, nb_col) end)
#   end
#   defp build_quick_reply(quick_reply, nb_col) do
#     %{
#       Columns: nb_col,
#       Rows: 1,
#       ActionType: "reply",
#       ActionBody: quick_reply.link,
#       Silent: true,
#       Text: "<font color='#ffffff'><b>#{quick_reply.title}</b></font>",
#       TextSize: "medium",
#       TextVAlign: "middle",
#       TextHAlign: "center",
#       BgColor: "#1568a0" # Blue #1568a0
#     }
#   end
#
#   defp build_rich_media(offer, msg, buttons) do
#     nb_rows = cond do
#       offer == nil -> 1 + calc_msg_rows(msg) # 1 row for buttons + text rows
#       true -> 4 + 1 + calc_msg_rows(msg) # 4 rows for image + 1 row for buttons + text rows (!! max 2)
#     end
#     %{
#       Type: "rich_media",
#       ButtonsGroupColumns: 6,
#       ButtonsGroupRows: nb_rows,
#       Buttons: build_rows(offer, msg, buttons),
#       BgColor: "#FFFFFF"
#     }
#   end
#   defp calc_msg_rows(msg) do
#     cond do
#       String.length(msg) < 50 -> 1
#       String.length(msg) < 150 -> 2
#       true -> 4 # Make sure this kind of message is never used with an offer (not enough space with an image)
#     end
#   end
#   defp build_rows(offer, msg, buttons) do
#     [build_image(offer), build_message(msg)] # Add image and msg
#       |> Enum.concat(build_btns(buttons)) # Add the buttons
#       |> Enum.reject(&is_nil/1) # Remove the nils from the final array
#   end
#
#   defp build_message(nil) do nil end
#   defp build_message(msg) do
#     %{
#         Columns: 6,
#         Rows: calc_msg_rows(msg),
#         ActionType: "none",
#         Text: msg,
#         TextSize: "medium",
#         TextVAlign: "middle",
#         TextHAlign: "left",
#       }
#   end
#
#   defp build_image(nil) do nil end
#   defp build_image(offer) do
#     image_url = List.first(offer.images)
#       |> BoncoinWeb.AnnounceView.image_url(:original)
#     %{
#       Columns: 6,
#       Rows: 4,
#       ActionType: "none",
#       Image: image_url
#     }
#   end
#
#   defp build_btns(nil) do nil end
#   defp build_btns(buttons) do
#     nb_columns = cond do
#       length(buttons) == 1 -> 6
#       length(buttons) == 2 -> 3
#       true -> 6 # Not normal to have more than 2 buttons but fallback to 6 by security
#     end
#     Enum.map(buttons, fn button -> build_button(button, nb_columns) end)
#   end
#
#   defp build_button(button, column) do
#     %{
#       Columns: column,
#       Rows: 1,
#       ActionType: button.action,
#       ActionBody: button.link,
#       Silent: true, # The Silent parameter is supported on devices running Viber version 6.7 and above.
#       TextSize: "medium",
#       TextVAlign: "middle",
#       TextHAlign: "middle",
#       Text: "<font color='#ffffff'><b>#{button.title}</b></font>",
#       BgColor: "#1568a0"
#     }
#   end
#
# end
