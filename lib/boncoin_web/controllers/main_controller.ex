defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{Contents, Members}

  def welcome(conn, _params) do
    nb_announces = Contents.count_announces_public()
    conn
      |> render(BoncoinWeb.PublicView, "welcome.html", nb_announces: nb_announces)
  end

  def public_index(conn, _params) do
    {announces, nb_announces, place} = Contents.list_announces_public(conn.assigns.search_params)
    |> IO.inspect()
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
    conn
      |> render(BoncoinWeb.LayoutView, "dashboard.html")
  end

end
