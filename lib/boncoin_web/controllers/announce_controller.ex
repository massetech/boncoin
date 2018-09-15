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

  # API to be called if user wants to load more offers on public page
  def add_offers_to_public_index(conn, %{"scope" => scope, "params" => %{"cursor_after" => cursor_after, "search_params" => search_params}} = params) do
    paginator_results = Contents.list_announces_public(cursor_after, search_params)
    offers = paginator_results.entries
      |> Enum.map(fn announce -> build_offer_html(announce) end)
    case paginator_results.metadata.after do
      nil -> # There are no more records after
        results = %{scope: scope, data: %{offers: offers, new_cursor_after: nil}, error: ""}
      new_cursor_after -> # There are still records after
        results = %{scope: scope, data: %{offers: offers, new_cursor_after: paginator_results.metadata.after}, error: ""}
    end
    # Count KPI add_more by township
    if search_params["township_id"] != "" do
      Contents.add_kpi_township_traffic(search_params["township_id"], "add_more")
    end
    render(conn, "offer_api.json", results: results)
  end

  defp build_offer_html(announce) do
    %{display_small: Phoenix.View.render_to_string(BoncoinWeb.AnnounceView, "_display_small.html", announce: announce),
      display_big: Phoenix.View.render_to_string(BoncoinWeb.AnnounceView, "_display_big.html", announce: announce)}
  end

  # API to be called if user wants to declare an alert on the offer
  def add_alert_to_offer(conn, %{"params" => offer_id, "scope" => scope} = params) do
    case Contents.add_alert_to_announce(offer_id) do
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
    render(conn, "index.html", announces: announces)
  end

  def new(conn, _params) do
    changeset = Contents.change_announce(%Announce{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"announce" => announce_params}) do
    case Contents.create_announce(announce_params) do
      {:ok, announce} ->
        conn
          |> put_flash(:info, gettext("Announce created successfully."))
          |> redirect(to: public_offers_path(conn, :public_index, search: %{township_id: "#{announce.township_id}"}))
      {:error, %Ecto.Changeset{} = changeset} ->
        msg = Announce.show_errors_in_msg(changeset)
        conn
          |> put_flash(:alert, msg)
          |> render("new.html", changeset: changeset)
    end
  end

  def treat(conn, params) do
    admin_user = Members.get_user!(conn.assigns.current_user.id)
    case Contents.validate_announce(admin_user, params) do
      {:ok, announce} ->
        conn
        |> put_flash(:info, "Announce treated successfully.")
        |> redirect(to: announce_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:alert, "Announce cannot be treated.")
        |> redirect(to: announce_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    refusal = Announce.refusal_causes()
    closing = Announce.admin_closing_causes()
    render(conn, "show.html", announce: announce, refusal_causes: refusal, closing_causes: closing)
  end

  def edit(conn, %{"link" => link}) do
    announce_id = Cipher.decrypt(link)
    case announce_id do
      {:error, msg} ->
        conn
          |> put_flash(:alert, "Sorry this link is broken.")
          |> redirect(to: root_path(conn, :welcome))
      announce_id ->
        announce = Contents.get_announce!(announce_id)
        case announce.status do
          "CLOSED" ->
            conn
              |> put_flash(:info, "This announce is now closed.")
              |> redirect(to: root_path(conn, :welcome))
          _ ->
            render(conn, "edit.html", announce: announce)
        end
    end
  end

  def close(conn, %{"announce_id" => id, "cause" => cause}) do
    announce = Contents.get_announce!(id)
    params = %{status: "CLOSED", closing_date: Timex.now(), cause: cause}
    case Contents.update_announce(announce, params) do
      {:ok, announce} ->
        conn
          |> put_flash(:info, gettext("Your offer has been removed."))
          |> redirect(to: root_path(conn, :welcome))
      {:error, %Ecto.Changeset{} = changeset} ->
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
