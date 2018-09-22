defmodule BoncoinWeb.CategoryController do
  use BoncoinWeb, :controller

  alias Boncoin.Contents
  alias Boncoin.Contents.Category

  def index(conn, _params) do
    categorys = Contents.list_categorys()
    render(conn, "index.html", categorys: categorys)
  end

  def new(conn, _params) do
    changeset = Contents.change_category(%Category{})
    familys = Contents.list_familys_for_select()
    render(conn, "new.html", changeset: changeset, familys: familys)
  end

  def create(conn, %{"category" => category_params}) do
    case Contents.create_category(category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: category_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        familys = Contents.list_familys_for_select()
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("new.html", changeset: changeset, familys: familys)
    end
  end

  def show(conn, %{"id" => id}) do
    category = Contents.get_category!(id)
    render(conn, "show.html", category: category)
  end

  def edit(conn, %{"id" => id}) do
    category = Contents.get_category!(id)
    familys = Contents.list_familys_for_select()
    changeset = Contents.change_category(category)
    render(conn, "edit.html", category: category, changeset: changeset, familys: familys)
  end

  def update(conn, %{"id" => id, "category" => category_params}) do
    category = Contents.get_category!(id)

    case Contents.update_category(category, category_params) do
      {:ok, category} ->
        conn
        |> put_flash(:info, "Category updated successfully.")
        |> redirect(to: category_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        familys = Contents.list_familys_for_select()
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("edit.html", category: category, changeset: changeset, familys: familys)
    end
  end

  def delete(conn, %{"id" => id}) do
    category = Contents.get_category!(id)
    {:ok, _category} = Contents.delete_category(category)
    conn
    |> put_flash(:info, "Category deleted successfully.")
    |> redirect(to: category_path(conn, :index))
  end
end
