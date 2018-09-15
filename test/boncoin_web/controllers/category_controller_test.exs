defmodule BoncoinWeb.CategoryControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory

  @create_attrs %{active: true, title_my: "some title_bi", title_en: "some title_en", icon: "fa-test", icon_type: "fa", rank: 2}
  @update_attrs %{active: false, title_my: "some updated title_bi", title_en: "some updated title_en", icon: "fa-test2", icon_type: "fas", rank: 1}
  @invalid_attrs %{active: true, title_my: nil, title_en: nil}
  @moduletag :admin_authenticated
  @moduletag :CategoryController
  @moduletag :Controller

  describe "index" do
    test "lists all categorys", %{conn: conn} do
      conn = get conn, category_path(conn, :index)
      assert html_response(conn, 200) =~ "Categorys"
    end
  end

  describe "new category" do
    test "renders form", %{conn: conn} do
      conn = get conn, category_path(conn, :new)
      assert html_response(conn, 200) =~ "New category"
    end
  end

  describe "create category" do
    test "redirects to show when data is valid", %{conn: conn} do
      family = insert(:family)
      conn = post conn, category_path(conn, :create), category: Map.put(@create_attrs, :family_id, family.id)
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "Category created successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, category_path(conn, :create), category: @invalid_attrs
      assert html_response(conn, 200) =~ "Errors, please check."
      assert html_response(conn, 200) =~ "New category"
    end
  end

  describe "edit category" do
    test "renders form for editing chosen category", %{conn: conn} do
      category = insert(:category)
      conn = get conn, category_path(conn, :edit, category)
      assert html_response(conn, 200) =~ "Edit category"
    end
  end

  describe "update category" do
    test "redirects when data is valid", %{conn: conn} do
      category = insert(:category)
      conn = put conn, category_path(conn, :update, category), category: @update_attrs
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "Category updated successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      category = insert(:category)
      conn = put conn, category_path(conn, :update, category), category: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit category"
      assert html_response(conn, 200) =~ "Errors, please check."
    end
  end

  describe "delete category" do
    test "deletes chosen category", %{conn: conn} do
      category = insert(:category)
      conn = delete conn, category_path(conn, :delete, category)
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "Category deleted successfully."
    end
  end
end
