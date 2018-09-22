defmodule BoncoinWeb.TownshipControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory

  @create_attrs %{active: true, title_my: "some title_bi", title_en: "some title_en"}
  @update_attrs %{active: false, title_my: "some updated title_bi", title_en: "some updated title_en"}
  @invalid_attrs %{active: true, title_my: nil, title_en: nil}
  @moduletag :admin_authenticated
  @moduletag :TownshipController
  @moduletag :Controller

  describe "index" do
    test "lists all townships", %{conn: conn} do
      conn = get conn, township_path(conn, :index)
      assert html_response(conn, 200) =~ "Townships"
    end
  end

  describe "new township" do
    test "renders form", %{conn: conn} do
      conn = get conn, township_path(conn, :new)
      assert html_response(conn, 200) =~ "New township"
    end
  end

  describe "create township" do
    test "redirects to show when data is valid", %{conn: conn} do
      division = insert(:division)
      conn = post conn, township_path(conn, :create), township: Map.put(@create_attrs, :division_id, division.id)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Township created successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, township_path(conn, :create), township: @invalid_attrs
      assert html_response(conn, 200) =~ "New township"
      assert html_response(conn, 200) =~ "Errors, please check"
    end
  end

  describe "edit township" do
    test "renders form for editing chosen township", %{conn: conn} do
      township = insert(:township)
      conn = get conn, township_path(conn, :edit, township)
      assert html_response(conn, 200) =~ "Edit township"
    end
  end

  describe "update township" do
    test "redirects when data is valid", %{conn: conn} do
      township = insert(:township)
      conn = put conn, township_path(conn, :update, township), township: @update_attrs
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Township updated successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      township = insert(:township)
      conn = put conn, township_path(conn, :update, township), township: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit township"
      assert html_response(conn, 200) =~ "Errors, please check"
    end
  end

  describe "delete township" do
    test "deletes chosen township", %{conn: conn} do
      township = insert(:township)
      conn = delete conn, township_path(conn, :delete, township)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Township deleted successfully."
    end
  end

end
