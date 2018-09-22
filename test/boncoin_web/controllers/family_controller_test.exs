defmodule BoncoinWeb.FamilyControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory

  @create_attrs %{active: true, title_my: "some title_bi", title_en: "some title_en", icon: "fa-test", icon_type: "fa", rank: 2}
  @update_attrs %{active: false, title_my: "some updated title_bi", title_en: "some updated title_en", icon: "fa-test2", icon_type: "fas", rank: 1}
  @invalid_attrs %{active: nil, title_my: nil, title_en: nil}
  @moduletag :admin_authenticated
  @moduletag :FamilyController
  @moduletag :Controller

  describe "index" do
    test "lists all familys", %{conn: conn} do
      conn = get conn, family_path(conn, :index)
      assert html_response(conn, 200) =~ "Familys"
    end
  end

  describe "new family" do
    test "renders form", %{conn: conn} do
      conn = get conn, family_path(conn, :new)
      assert html_response(conn, 200) =~ "New family"
    end
  end

  describe "create family" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post conn, family_path(conn, :create), family: @create_attrs
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Family created successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, family_path(conn, :create), family: @invalid_attrs
      assert html_response(conn, 200) =~ "New family"
      assert html_response(conn, 200) =~ "Errors, please check"
    end
  end

  describe "edit family" do
    test "renders form for editing chosen family", %{conn: conn} do
      family = insert(:family)
      conn = get conn, family_path(conn, :edit, family)
      assert html_response(conn, 200) =~ "Edit family"
    end
  end

  describe "update family" do
    test "redirects when data is valid", %{conn: conn} do
      family = insert(:family)
      conn = put conn, family_path(conn, :update, family), family: @update_attrs
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Family updated successfully."
    end
    test "renders errors when data is invalid", %{conn: conn} do
      family = insert(:family)
      conn = put conn, family_path(conn, :update, family), family: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit family"
      assert html_response(conn, 200) =~ "Errors, please check"
    end
  end

  describe "delete family" do
    test "deletes chosen family", %{conn: conn} do
      family = insert(:family)
      conn = delete conn, family_path(conn, :delete, family)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Family deleted successfully."
    end
  end

end
