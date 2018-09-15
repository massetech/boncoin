defmodule BoncoinWeb.DivisionController do
  use BoncoinWeb, :controller

  alias Boncoin.Contents
  alias Boncoin.Contents.Division

  def index(conn, _params) do
    divisions = Contents.list_divisions()
    render(conn, "index.html", divisions: divisions)
  end

  def new(conn, _params) do
    changeset = Contents.change_division(%Division{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"division" => division_params}) do
    case Contents.create_division(division_params) do
      {:ok, division} ->
        conn
        |> put_flash(:info, "Division created successfully.")
        |> put_status(308)
        |> redirect(to: category_path(conn, :index))
        |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:alert, "Errors, please check.")
        |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    division = Contents.get_division!(id)
    render(conn, "show.html", division: division)
  end

  def edit(conn, %{"id" => id}) do
    division = Contents.get_division!(id)
    changeset = Contents.change_division(division)
    render(conn, "edit.html", division: division, changeset: changeset)
  end

  def update(conn, %{"id" => id, "division" => division_params}) do
    division = Contents.get_division!(id)

    case Contents.update_division(division, division_params) do
      {:ok, division} ->
        conn
        |> put_flash(:info, "Division updated successfully.")
        |> put_status(308)
        |> redirect(to: category_path(conn, :index))
        |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("edit.html", division: division, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    division = Contents.get_division!(id)
    {:ok, _division} = Contents.delete_division(division)
    conn
    |> put_flash(:info, "Division deleted successfully.")
    |> put_status(308)
    |> redirect(to: category_path(conn, :index))
    |> halt()
  end
end
