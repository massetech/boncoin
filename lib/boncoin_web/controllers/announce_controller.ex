defmodule BoncoinWeb.AnnounceController do
  use BoncoinWeb, :controller
  use Drab.Controller, commanders: [BoncoinWeb.AnnounceCommander]
  alias Boncoin.{Contents, Members}
  alias Boncoin.Contents.Announce

  def public_index(conn, _params) do
    paginator_results = Contents.list_announces_public(nil, conn.assigns.search_params)
    conn
      |> assign(:cursor_after, paginator_results.metadata.after)
      |> assign(:nb_offers_found, paginator_results.metadata.total_count)
      |> render("public_index.html", announces: paginator_results.entries)
  end

  def likes_index(conn, _params) do
    IO.inspect(conn.assigns)
    results = conn.assigns.likes_list
      |> Poison.decode!()
      |> Contents.list_announces_public_liked()
    conn
      |> assign(:nb_offers_found, Enum.count(results))
      |> render("public_likes.html", announces: results)
  end

  # API to be called if user wants to load more offers on public page
  def add_offers_to_public_index(conn, %{"scope" => scope, "params" => %{"cursor_after" => cursor_after, "search_params" => search_params}}) do
    paginator_results = Contents.list_announces_public(cursor_after, search_params)
    conn
      |> assign(:refusal_causes, Announce.refusal_causes())
      |> assign(:closing_causes, Announce.admin_closing_causes())
    offers = paginator_results.entries
      |> build_offers_html(conn)
      # |> Enum.map(fn announce -> build_offers_html(conn, announce) end)
    results = case paginator_results.metadata.after do
      nil -> # There are no more records after
        %{scope: scope, data: %{offers: offers, new_cursor_after: nil}, error: ""}
      _new_cursor_after -> # There are still records after
        %{scope: scope, data: %{offers: offers, new_cursor_after: paginator_results.metadata.after}, error: ""}
    end
    # Count KPI add_more by township
    if search_params["township_id"] != "" do
      Contents.add_kpi_township_traffic(search_params["township_id"], "add_more")
    end
    render(conn, "offer_api.json", results: results)
  end

  defp build_offers_html(announces, conn) do
    %{inline_html: Phoenix.View.render_to_string(BoncoinWeb.AnnounceView, "_public_list_offers.html", announces: announces, conn: conn)}
  end

  # API to be called if user wants to declare an alert on the offer
  def add_alert_to_offer(conn, %{"params" => offer_id, "scope" => scope}) do
    case Contents.add_alert_to_announce(offer_id) do
      {:ok, _} ->
        results = %{scope: scope, data: %{offer_id: offer_id}, error: ""}
        render(conn, "offer_api.json", results: results)
      {:error, msg} ->
        results = %{scope: scope, data: %{}, error: msg}
        render(conn, "offer_api.json", results: results)
    end
  end

  def add_click_on_offer(conn, %{"params" => offer_id, "scope" => scope}) do
    case Contents.add_clic_to_announce(offer_id) do
      {:ok, _} ->
        results = %{scope: scope, data: %{offer_id: offer_id}, error: ""}
        render(conn, "offer_api.json", results: results)
      {:error, msg} ->
        results = %{scope: scope, data: %{}, error: msg}
        render(conn, "offer_api.json", results: results)
    end
  end

  def index(conn, _params) do
    announces = Contents.list_announces()
    refusal = Announce.refusal_causes()
    closing = Announce.admin_closing_causes()
    render(conn, "index.html", announces: announces, refusal_causes: refusal, closing_causes: closing)
  end

  def treat(conn, params) do
    admin_user = Members.get_user!(conn.assigns.current_user.id)
    case Contents.treat_announce(admin_user, params) do
      {:ok, msg, _user_messages} ->
        conn
        |> put_flash(:info, "Offer treated and #{msg}")
        |> redirect(to: announce_path(conn, :index))
      {:error, _, _} ->
        conn
        |> put_flash(:alert, gettext("Technical problem, cannot treat this offer."))
        |> redirect(to: announce_path(conn, :index))
    end
  end

  def show(conn, %{"link" => link}) do
    announce_id = Cipher.decrypt(link)
    case announce_id do
      {:error, _msg} ->
        conn
          |> put_flash(:alert, gettext("Sorry, this offer doesn't exist."))
          |> redirect(to: root_path(conn, :welcome))
      announce_id ->
        announce = Contents.get_announce!(announce_id)
        case announce.status do
          "CLOSED" ->
            conn
              |> put_flash(:info, gettext("This offer is no more published."))
              |> redirect(to: root_path(conn, :welcome))
          _ ->
            render(conn, "show.html", announce: announce)
        end
    end
  end

  def close(conn, %{"announce_id" => id, "cause" => cause}) do
    announce = Contents.get_announce!(id)
    params = %{status: "CLOSED", closing_date: Timex.now(), cause: cause}
    case Contents.update_announce(announce, params) do
      {:ok, _announce} ->
        conn
          |> put_flash(:info, gettext("Your offer has been closed and is no more online."))
          |> redirect(to: root_path(conn, :welcome))
      {:error, _changeset} ->
        render(conn, "edit.html", announce: announce)
    end
  end

  def delete(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    {:ok, _announce} = Contents.delete_announce(announce)
    conn
    |> put_flash(:info, "Offer deleted successfully.")
    |> put_status(308)
    |> redirect(to: announce_path(conn, :index))
    |> halt()
  end
end
