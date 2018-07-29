defmodule BoncoinWeb.AnnounceController do
  use BoncoinWeb, :controller
  use Drab.Controller, commanders: [BoncoinWeb.AnnounceCommander]
  alias Boncoin.{Contents, Members}
  alias Boncoin.Contents.Announce

  def index(conn, _params) do
    announces = Contents.list_announces()
    render(conn, "index.html", announces: announces)
  end

  def treat_announce(conn, params) do
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

  def new(conn, _params) do
    IO.inspect(conn)
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

  def show(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    render(conn, "show.html", announce: announce, refusal_causes: Announce.refusal_causes())
  end

  # def edit(conn, %{"id" => id}) do
  #   announce = Contents.get_announce!(id)
  #   changeset = Contents.change_announce(announce)
  #   render(conn, "edit.html", announce: announce, changeset: changeset)
  # end
  #
  # def update(conn, %{"id" => id, "announce" => announce_params}) do
  #   announce = Contents.get_announce!(id)
  #
  #   case Contents.update_announce(announce, announce_params) do
  #     {:ok, announce} ->
  #       conn
  #       |> put_flash(:info, "Announce updated successfully.")
  #       |> redirect(to: announce_path(conn, :show, announce))
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", announce: announce, changeset: changeset)
  #   end
  # end

  def delete(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    {:ok, _announce} = Contents.delete_announce(announce)

    conn
    |> put_flash(:info, "Announce deleted successfully.")
    |> redirect(to: announce_path(conn, :index))
  end
end
