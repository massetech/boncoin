defmodule BoncoinWeb.AnnounceController do
  use BoncoinWeb, :controller
  use Drab.Controller, commanders: [BoncoinWeb.AnnounceCommander]
  alias Boncoin.{Contents, Members}
  alias Boncoin.Contents.Announce

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
        |> put_flash(:info, "Announce created successfully.")
        |> redirect(to: public_offers_path(conn, :public_index, search: %{township_id: "#{announce.township_id}"}))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
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
        |> put_flash(:alert, "Sorry this announce can't be found.")
        |> redirect(to: root_path(conn, :welcome))
      announce_id ->
        announce = Contents.get_announce!(announce_id)
        case announce.status do
          "CLOSED" ->
            conn
            |> put_flash(:alert, "This announce is now closed.")
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
        |> put_flash(:info, "The offer has been removed.")
        |> redirect(to: root_path(conn, :welcome))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", announce: announce)
    end
  end

  def delete(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    {:ok, _announce} = Contents.delete_announce(announce)

    conn
    |> put_flash(:info, "Announce deleted successfully.")
    |> redirect(to: announce_path(conn, :index))
  end
end
