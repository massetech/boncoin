defmodule BoncoinWeb.AnnounceController do
  use BoncoinWeb, :controller

  alias Boncoin.Contents
  alias Boncoin.Contents.Announce

  def index(conn, _params) do
    announces = Contents.list_announces()
    render(conn, "index.html", announces: announces)
  end

  def public_index(conn, _params) do
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
        |> redirect(to: announce_path(conn, :show, announce))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    render(conn, "show.html", announce: announce)
  end

  def edit(conn, %{"id" => id}) do
    announce = Contents.get_announce!(id)
    changeset = Contents.change_announce(announce)
    render(conn, "edit.html", announce: announce, changeset: changeset)
  end

  def update(conn, %{"id" => id, "announce" => announce_params}) do
    announce = Contents.get_announce!(id)

    case Contents.update_announce(announce, announce_params) do
      {:ok, announce} ->
        conn
        |> put_flash(:info, "Announce updated successfully.")
        |> redirect(to: announce_path(conn, :show, announce))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", announce: announce, changeset: changeset)
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
