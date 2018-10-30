defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Contents}

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
    viber_status = ViberApi.check_online()
    conn
      |> assign(:viber_status, viber_status)
      |> render(BoncoinWeb.PublicView, "dashboard.html")
  end

end
