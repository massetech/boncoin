defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Contents, Members}

  def welcome(conn, _params) do
    nb_announces = Contents.count_announces_public()
    conn
      |> render(BoncoinWeb.PublicView, "welcome.html", nb_announces: nb_announces)
  end

  def conditions(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "conditions.html")
  end

  def about(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "about.html")
  end

  def conversations(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "conversations.html")
  end

  def dashboard(conn, _params) do
    # Test the Viber webhook
    IO.puts("Webhook tested at #{Timex.now()}")
    params = %{ids: ["01234567890="]}
    answer = ViberApi.post("get_online", params)
    viber_status = case answer do
      {:ok, resp} -> "online"
      {:error, resp} ->
        IO.puts("Problems on Viber Webhook not set")
        IO.inspect(resp)
        "offline"
    end
    conn
      |> assign(:viber_status, viber_status)
      |> render(BoncoinWeb.PublicView, "dashboard.html")
  end

end
