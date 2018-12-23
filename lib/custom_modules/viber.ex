defmodule Boncoin.ViberApi do
  use BoncoinWeb, :controller # Added for test functions only
  alias Boncoin.{Members, Contents} # Added for test functions only
  alias Boncoin.CustomModules.BotDecisions # Added for test functions only
  @api_url "https://chatapi.viber.com/pa/"

  # //// MANUAL TESTS OF VIBER BOT .....
  # Test manually the user sending a msg (nil message not possible)
  def test_viber_new_message(user_id, user_msg) do
    user = Members.get_user(user_id)
    params = %{"event" => "message", "timestamp" => "time for lunch", "sender" => %{"id" => user.conversation.psid, "name" => user.nickname}, "message" => %{"type" => "text", "text" => user_msg}}
    conn = %Plug.Conn{private: %{phoenix_endpoint: BoncoinWeb.Endpoint}}
      |> assign(:current_user, user)
    BoncoinWeb.ViberController.callback(conn, params)
  end
  # Test manually the user receiving his offer published
  def test_viber_offer_published(user_id, offer_id) do
    user = Members.get_user(user_id)
    offer = Contents.get_announce!(offer_id)
    %{user: user, conversation: Map.put(user.conversation, :scope, "offer_treated"), announce: offer, user_msg: ""}
      |> BotDecisions.call_bot_algorythm()
      |> IO.inspect()
      |> Members.send_bot_message_to_user(offer, :update)
  end

  # --------------------------------------------------------------------------

  # API doc https://developers.viber.com/docs/api/rest-bot-api/#general-send-message-parameters
  def send_message(type, psid, msg, quick_replies, buttons, offer) do
    # Using Viber keyboards : https://developers.viber.com/docs/tools/keyboards/
    cond do
      offer == nil -> # Send a BUTTON message
        %{receiver: psid, min_api_version: 1, type: "text", text: msg, keyboard: build_keyboard(buttons, quick_replies)}
          # |> IO.inspect()
          |> post("send_message")
      true -> # Send a GENERIC message
        %{receiver: psid, min_api_version: 2, type: "rich_media", rich_media: built_rich_media(offer, msg), keyboard: build_keyboard(buttons, quick_replies)}
          # |> IO.inspect()
          |> post("send_message")
    end
  end

  def check_online() do
    IO.puts("Webhook tested at #{Timex.now()}")
    case post(%{ids: ["01234567890="]}, "get_online") do
      {:ok, _resp} -> "online"
      {:error, resp} ->
        IO.puts("Problems on Viber Webhook not set")
        IO.inspect(resp)
        "offline"
    end
  end

  def post(payload \\ %{}, path) do
    token = get_viber_token()
    uri = URI.merge(@api_url, path) |> to_string
    resp = HTTPoison.post uri, Jason.encode!(payload), prepare_headers(token)
    case resp do
      {:ok, response} ->
        response.body
          |> Jason.decode
          |> handle_response
      {:error, msg} ->
        IO.puts("The request was not posted to Viber (Elixir internal problem)")
        IO.inspect(msg)
    end
  end

  defp get_viber_token() do
    Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:viber_secret]
  end

  defp prepare_headers(access_token) do
    ["Content-Type": "application/json", "X-Viber-Auth-Token": access_token]
  end

  defp handle_response({:ok, resp}), do: if resp["status"] > 0, do: {:error, resp}, else: {:ok, resp}
  defp handle_response(_), do: {:error, "Unexpected response from Viber"}

  defp build_keyboard(buttons, quick_replies) do
    btn_list = Enum.map(buttons, fn button -> build_big_button(button) end)
    reply_list = Enum.map(quick_replies, fn reply -> build_small_button(reply) end)
    buttons_list = reply_list ++ btn_list
    case buttons_list do
      [] -> nil
      _ ->
        %{
          Type: "keyboard",
          DefaultHeight: false,
          BgColor: "#ffec00",
          Buttons: buttons_list
        }
    end
  end
  defp build_small_button(quick_reply) do
    %{
      Columns: 2,
      Rows: 1,
      ActionType: "reply",
      ActionBody: quick_reply.link,
      Silent: false,
      Text: "<font color='#ffffff'><b>#{quick_reply.title}</b></font>",
      TextSize: "medium",
      TextVAlign: "middle",
      TextHAlign: "center",
      BgColor: "#1568a0"
    }
  end
  defp build_big_button(button) do
    if button.link =~ "http" do
      %{
        Columns: 6,
        Rows: 1,
        ActionType: "open-url",
        ActionBody: button.link,
        Silent: true,
        Text: "<font color='#ffffff'><b>#{button.title}</b></font>",
        TextSize: "medium",
  			TextVAlign: "middle",
  			TextHAlign: "center",
        BgColor: "#1568a0"
  		}
    else
      %{
        Columns: 6,
        Rows: 1,
        ActionType: "reply",
        ActionBody: button.link,
        Silent: false,
        Text: "<font color='#ffffff'><b>#{button.title}</b></font>",
        TextSize: "medium",
        TextVAlign: "middle",
        TextHAlign: "center",
        BgColor: "#1568a0"
      }
    end
  end

  defp built_rich_media(offer, msg) do
    image_url = List.first(offer.images)
      |> BoncoinWeb.AnnounceView.image_url(:original)
    offer_url = Boncoin.CustomModules.BotDecisions.offer_view_link(offer.id)
    %{
      Type: "rich_media",
      ButtonsGroupColumns: 6,
      ButtonsGroupRows: 7,
      BgColor: "#FFFFFF",
      Buttons: [
        %{
          Columns: 6,
          Rows: 4,
          ActionType: "open-url",
          ActionBody: offer_url,
          Silent: true,
          Image: image_url
        },
        %{
          Columns: 6,
          Rows: 2,
          ActionType: "none",
          Text: msg,
          TextSize: "medium",
          TextVAlign: "middle",
          TextHAlign: "left",
        },
        %{
          Columns: 6,
          Rows: 1,
          ActionType: "open-url",
          ActionBody: offer_url,
          Silent: true,
          TextSize: "medium",
          TextVAlign: "middle",
          TextHAlign: "middle",
          Text: "<font color='#ffffff'><b>SEE OFFER</b></font>",
          BgColor: "#1568a0"
        }
      ]
    }
  end

end
