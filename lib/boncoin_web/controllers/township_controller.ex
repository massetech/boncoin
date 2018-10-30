defmodule BoncoinWeb.TownshipController do
  use BoncoinWeb, :controller

  alias Boncoin.Contents
  alias Boncoin.Contents.Township

  def index(conn, _params) do
    townships = Contents.list_townships()
    render(conn, "index.html", townships: townships)
  end

  def new(conn, _params) do
    changeset = Contents.change_township(%Township{})
    divisions = Contents.list_divisions_for_select()
    render(conn, "new.html", changeset: changeset, divisions: divisions)
  end

  def create(conn, %{"township" => township_params}) do
    case Contents.create_township(township_params) do
      {:ok, _township} ->
        conn
        |> put_flash(:info, "Township created successfully.")
        |> redirect(to: township_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        divisions = Contents.list_divisions_for_select()
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("new.html", changeset: changeset, divisions: divisions)
    end
  end

  def show(conn, %{"id" => id}) do
    township = Contents.get_township!(id)
    render(conn, "show.html", township: township)
  end

  def edit(conn, %{"id" => id}) do
    township = Contents.get_township!(id)
    divisions = Contents.list_divisions_for_select()
    changeset = Contents.change_township(township)
    render(conn, "edit.html", township: township, changeset: changeset, divisions: divisions)
  end

  def update(conn, %{"id" => id, "township" => township_params}) do
    township = Contents.get_township!(id)

    case Contents.update_township(township, township_params) do
      {:ok, _township} ->
        conn
          |> put_flash(:info, "Township updated successfully.")
          |> redirect(to: township_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        divisions = Contents.list_divisions_for_select()
        conn
          |> put_flash(:info, "Errors, please check.")
          |> render("edit.html", township: township, changeset: changeset, divisions: divisions)
    end
  end

  def delete(conn, %{"id" => id}) do
    township = Contents.get_township!(id)
    {:ok, _township} = Contents.delete_township(township)
    conn
    |> put_flash(:info, "Township deleted successfully.")
    |> redirect(to: category_path(conn, :index))
  end
end
