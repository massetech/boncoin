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
        |> redirect(to: family_path(conn, :show, family))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
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
        |> redirect(to: family_path(conn, :show, family))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", family: family, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    family = Contents.get_family!(id)
    {:ok, _family} = Contents.delete_family(family)

    conn
    |> put_flash(:info, "Family deleted successfully.")
    |> redirect(to: family_path(conn, :index))
  end
end
