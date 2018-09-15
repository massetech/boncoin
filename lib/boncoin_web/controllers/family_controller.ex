defmodule BoncoinWeb.FamilyController do
  use BoncoinWeb, :controller

  alias Boncoin.Contents
  alias Boncoin.Contents.Family

  def index(conn, _params) do
    familys = Contents.list_familys()
    render(conn, "index.html", familys: familys)
  end

  def new(conn, _params) do
    changeset = Contents.change_family(%Family{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"family" => family_params}) do
    case Contents.create_family(family_params) do
      {:ok, family} ->
        conn
        |> put_flash(:info, "Family created successfully.")
        |> put_status(308)
        |> redirect(to: category_path(conn, :index))
        |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    family = Contents.get_family!(id)
    render(conn, "show.html", family: family)
  end

  def edit(conn, %{"id" => id}) do
    family = Contents.get_family!(id)
    changeset = Contents.change_family(family)
    render(conn, "edit.html", family: family, changeset: changeset)
  end

  def update(conn, %{"id" => id, "family" => family_params}) do
    family = Contents.get_family!(id)
    case Contents.update_family(family, family_params) do
      {:ok, family} ->
        conn
        |> put_flash(:info, "Family updated successfully.")
        |> put_status(308)
        |> redirect(to: category_path(conn, :index))
        |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("edit.html", family: family, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    family = Contents.get_family!(id)
    {:ok, _family} = Contents.delete_family(family)
    conn
    |> put_flash(:info, "Family deleted successfully.")
    |> put_status(308)
    |> redirect(to: category_path(conn, :index))
    |> halt()
  end
end
