defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{ViberApi, Contents}
  alias Boncoin.Etag

  def welcome(conn, _params) do
    nb_announces = Contents.count_announces_public()
    conn
      |> put_flash(:info, welcome_message(conn))
      # |> put_flash(:alert, welcome_message(conn))
      # |> put_flash(:success, welcome_message(conn))
      |> Etag.render_or_cache(BoncoinWeb.PublicView, "welcome.html", %{nb_announces: nb_announces})
  end

  defp welcome_message(conn) do
    gettext("Welcome on Pawchaungkaung !")
  end

  def conditions(conn, _params) do
    conn
      |> Etag.render_or_cache(BoncoinWeb.PublicView, "conditions.html", %{})
  end

  def about(conn, _params) do
    conn
      |> Etag.render_or_cache(BoncoinWeb.PublicView, "about.html", %{})
  end

  def conversations(conn, _params) do
    conn
      |> Etag.render_or_cache(BoncoinWeb.PublicView, "conversations.html", %{})
  end

  def dashboard(conn, _params) do
    viber_status = ViberApi.check_online()
    conn
      |> assign(:viber_status, viber_status)
      |> put_view(BoncoinWeb.PublicView)
      |> render("dashboard.html")
  end

end
