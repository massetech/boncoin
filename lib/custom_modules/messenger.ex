defmodule Boncoin.MessengerApi do
  @api_url "https://graph.facebook.com/v2.6/me/messages"
  @api_profile_url "https://graph.facebook.com"

  def send_message(messenger_id, user_msg) do
    # Find options into [] and build the Messenger quick replies buttons
    # quick_replies = cond do
    #   scope =~ "phone" -> [%{content_type: "user_phone_number", payload: scope}]
    #   scope == "" -> []
    #   true ->
    #     Regex.scan(~r/\[.*?\]/, user_msg)
    #       |> List.flatten()
    #       |> Enum.map(&build_quick_reply(&1, scope))
    # end
    %{recipient: %{id: messenger_id}, message: %{text: user_msg}}
      |> post()
  end

  # defp build_quick_reply(option_text, scope) do
  #   text = option_text
  #     |> String.replace("[", "")
  #     |> String.replace("]", "")
  #   %{content_type: "text", title: text, payload: scope}
  # end

  defp post(payload) do
    resp = HTTPotion.post prepare_post_url(), headers: ["Content-Type": "application/json"], body: Poison.encode!(payload)
    resp.body
      |> Poison.decode
      |> handle_response
  end

  def get_user_profile(psid) do
    resp = HTTPotion.get prepare_profile_url(psid)
    map = resp.body
      |> Poison.decode
      |> handle_response
    case map do
      {:ok, map} -> map["first_name"]
      {:error, _msg} -> ""
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

end
