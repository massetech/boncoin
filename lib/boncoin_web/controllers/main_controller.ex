defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Contents, Members}

  def welcome(conn, _params) do
    nb_announces = Contents.count_announces_public()
    conn
      |> IO.inspect()
      |> render(BoncoinWeb.PublicView, "welcome.html", nb_announces: nb_announces)
  end

  def public_index(conn, _params) do
    {announces, nb_announces, place} = Contents.list_announces_public(conn.assigns.search_params)
    conn
      |> render(BoncoinWeb.PublicView, "announces_index.html", announces: announces, nb_announces: nb_announces, place: place)
  end

  def conditions(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "conditions.html")
  end

  def about(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "about.html")
  end

  def viber(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "viber.html")
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
      |> IO.inspect()
      |> render(BoncoinWeb.PublicView, "dashboard.html")
  end

end
