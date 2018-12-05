defmodule Boncoin.MessengerApi do
  @api_url "https://graph.facebook.com/v2.6/me/messages"
  @api_profile_url "https://graph.facebook.com"

  # API doc https://developers.facebook.com/docs/messenger-platform/reference/send-api/
  def send_answer_message(messenger_id, user_msg) do
    %{messaging_type: "RESPONSE", recipient: %{id: messenger_id}, message: %{text: user_msg}}
      |> post()
  end
  def send_update_message(messenger_id, user_msg) do
    %{messaging_type: "UPDATE", recipient: %{id: messenger_id}, message: %{text: user_msg}}
      |> post()
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
        IO.puts("No first_name received in Messenger respnse")
        ""
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
