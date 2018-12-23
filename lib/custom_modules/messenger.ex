defmodule Boncoin.MessengerApi do
  @api_url "https://graph.facebook.com/v2.6/me/messages"
  @api_profile_url "https://graph.facebook.com"

  # API doc https://developers.facebook.com/docs/messenger-platform/reference/send-api/
  def send_message(type, psid, msg, quick_replies, buttons, offer) do
    cond do
      offer == nil && buttons == [] -> # Send a TEXT message
        %{messaging_type: type, recipient: %{id: psid}, message: %{text: msg, quick_replies: build_quick_replies(quick_replies)}}
          # |> IO.inspect()
          |> post()
      offer == nil && buttons != [] -> # Send a BUTTON message
        %{messaging_type: type, recipient: %{id: psid}, message: %{quick_replies: build_quick_replies(quick_replies), attachment: build_button_attachment(msg, buttons)}}
          # |> IO.inspect()
          |> post()
      true -> # Send a GENERIC message
        %{messaging_type: type, recipient: %{id: psid}, message: %{attachment: build_generic_attachment(offer, msg)}}
          # |> IO.inspect()
          |> post()
    end
  end

  defp post(payload) do
    uri = prepare_post_url()
    resp = HTTPoison.post uri, Jason.encode!(payload), [{"Content-Type", "application/json"}]
    case resp do
      {:ok, response} ->
        response.body
          |> Jason.decode
          |> handle_response
      {:error, msg} ->
        IO.puts("The request was not posted to Messenger (Elixir internal problem)")
        IO.inspect(msg)
    end
  end

  def get_user_profile(psid) do
    resp = HTTPoison.get prepare_profile_url(psid)
    case resp do
      {:ok, response} ->
        detail_map = response.body
          |> Jason.decode
          |> handle_response
        case detail_map do
          {:ok, %{"first_name" => first_name}} -> first_name
          {:ok, _} -> default_nickname()
          {:error, msg} ->
            IO.puts(msg)
            default_nickname()
        end
      {:error, msg} ->
        IO.puts("The request was not posted to Messenger (Elixir internal problem)")
        IO.inspect(msg)
        default_nickname()
    end
  end

  defp default_nickname() do
    case Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:environment] do
      :test -> "mr_X"
      _ ->
        IO.puts("No first_name received in Messenger response")
        " "
    end
  end

  def prepare_profile_url(psid) do
    page_token = Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:messenger_page_access]
    query = "?access_token=#{page_token}"
    "#{@api_profile_url}/#{psid}#{query}"
  end

  defp prepare_post_url() do
    page_token = Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:messenger_page_access]
    query = "?access_token=#{page_token}"
    "#{@api_url}#{query}"
  end

  defp handle_response({:ok, resp}), do: {:ok, resp}
  defp handle_response(_), do: {:error, "Unexpected response from Messenger"}

  defp build_quick_replies(quick_replies) do
    case Enum.map(quick_replies, fn quick_reply -> build_quick_reply(quick_reply) end) do
      [] -> nil
      list -> list
    end
  end
  defp build_quick_reply(quick_reply) do
    %{
      content_type: "text",
      payload: quick_reply.link,
      title: quick_reply.title
    }
  end
  defp build_button_attachment(msg, buttons) do
    case buttons do
      [] -> nil
      _ ->
        %{
          type: "template",
          payload: %{
            template_type: "button",
            text: msg,
            buttons: Enum.map(buttons, fn button -> build_button(button) end)
          }
        }
    end
  end
  defp build_button(button) do
    if button.link =~ "http" do
      %{
        type: "web_url",
        url: button.link,
        title: button.title
      }
    else
      %{
        type: "postback",
        payload: button.link,
        title: button.title
      }
    end
  end

  defp build_generic_attachment(offer, msg) do
    image_url = List.first(offer.images)
      |> BoncoinWeb.AnnounceView.image_url(:original)
    offer_url = Boncoin.CustomModules.BotDecisions.offer_view_link(offer.id)
    %{
      type: "template",
      payload: %{
        template_type: "generic",
        sharable: false,
        elements: [
          %{
            title: offer.title,
            subtitle: msg,
            image_url: image_url,
            buttons: [
              %{
                type: "web_url",
                url: offer_url,
                title: "View offer",
              }
            ]
          }
        ]
      }
    }
  end

end
