defmodule Boncoin.ViberApi do
  @api_url "https://chatapi.viber.com/pa/"
  # @token Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:viber_secret]
  # @token System.get_env("VIBER_SECRET")

  # Usage examples
  # ==============
  #
  # Get Public Account info
  # -----------------------
  # ViberApi.get("get_account_info", token)
  #
  # Set webhook
  # -----------
  # ViberApi.post("set_webhook", token,
  #     %{
  #       url: "https://my-app.example.com/callback",
  #       event_types: ["delivered", "seen", "failed", "subscribed", "unsubscribed", "conversation_started"]
  #     }
  # )
  #   Response
  # -----------
  #   {
  #    "status":0,
  #    "status_message":"ok",
  #    "event_types":[
  #       "delivered",
  #       "seen",
  #       "failed",
  #       "subscribed",
  #       "unsubscribed",
  #       "conversation_started"
  #    ]
  # }
  #
  # Remove webhook
  # --------------
  # ViberApi.post("set_webhook", token, %{url: ""})
  #
  # Send message
  # ------------
  # ViberApi.post("send_message", token, %{
  #                               receiver: "01234567890A=",
  #                               sender: %{
  #                                 name: "John McClane",
  #                                 avatar: "https://avatar.example.com/1.jpg"
  #                               },
  #                               type: "text",
  #                               text: "Test from ViberApi"
  #                             })
  # Communication started Callback
  # ------------
  #   %{
  #     "event" => "conversation_started",
  #     "message_token" => 5202400270959897633,
  #     "sig" => "8a1523aa0fe6acfe92a62754fdb92f74dbff1b2d186ad3e5ccc67d7e405a44ad",
  #     "subscribed" => false,
  #     "timestamp" => 1532406656647,
  #     "type" => "open",
  #     "user" => %{
  #       "api_version" => 6,
  #       "avatar" => nil,
  #       "country" => "MM",
  #       "id" => "hPAtCbK9yIaDQumAoQ50sQ==",
  #       "language" => "fr",
  #       "name" => "Thib"
  #     }
  #   }

  def get(path) do
    token = get_viber_token()
    IO.puts("token: #{token}")
    uri = URI.merge(@api_url, path) |> to_string
    resp = HTTPotion.get uri, headers: prepare_headers(token)
    resp.body |> Poison.decode |> handle_response
  end

  def post(path, payload \\ %{}) do
    token = get_viber_token()
    IO.puts("token: #{token}")
    uri = URI.merge(@api_url, path) |> to_string
    resp = HTTPotion.post uri, body: Poison.encode!(payload), headers: prepare_headers(token)
    resp.body
      |> Poison.decode
      |> handle_response
  end

  defp get_viber_token() do
    Application.get_env(:boncoin, BoncoinWeb.Endpoint)[:viber_secret]
  end

  defp prepare_headers(access_token) do
    ["Content-Type": "application/json", "X-Viber-Auth-Token": access_token]
  end

  defp handle_response({:ok, resp}), do: if resp["status"] > 0, do: {:error, resp}, else: {:ok, resp}
  defp handle_response(_), do: {:error, "Unexpected response"}

end
