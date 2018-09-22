defmodule BoncoinWeb.DivisionControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory

  @create_attrs %{active: true, title_my: "some title_bi", title_en: "some title_en"}
  @update_attrs %{active: false, title_my: "some updated title_bi", title_en: "some updated title_en"}
  @invalid_attrs %{active: true, title_my: nil, title_en: nil}
  @moduletag :admin_authenticated
  @moduletag :DivisionController
  @moduletag :Controller

  describe "index" do
    test "lists all divisions", %{conn: conn} do
      conn = get conn, division_path(conn, :index)
      assert html_response(conn, 200) =~ "Divisions"
    end
  end

  describe "new division" do
    test "renders form", %{conn: conn} do
      conn = get conn, division_path(conn, :new)
      assert html_response(conn, 200) =~ "New division"
    end
  end

  describe "create division" do
    test "render index when data is valid", %{conn: conn} do
      conn = post conn, division_path(conn, :create), division: @create_attrs
      # IO.inspect(html_response(conn, 200), limit: :infinity, printable_limit: :infinity)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Division created successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, division_path(conn, :create), division: @invalid_attrs
      assert html_response(conn, 200) =~ "New division"
      assert html_response(conn, 200) =~ "Errors, please check"
    end
  end

  describe "edit division" do
    test "renders form for editing chosen division", %{conn: conn} do
      division = insert(:division)
      conn = get conn, division_path(conn, :edit, division)
      assert html_response(conn, 200) =~ "Edit division"
    end
  end

  describe "update division" do
    test "redirects when data is valid", %{conn: conn} do
      division = insert(:division)
      conn = put conn, division_path(conn, :update, division), division: @update_attrs
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Division updated successfully."
    end

    test "renders errors when data is invalid", %{conn: conn} do
      division = insert(:division)
      conn = put conn, division_path(conn, :update, division), division: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit division"
      assert html_response(conn, 200) =~ "Errors, please check."
    end
  end

  describe "delete division" do
    test "deletes chosen division", %{conn: conn} do
      division = insert(:division)
      conn = delete conn, division_path(conn, :delete, division)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Division deleted successfully."
    end
  end
end
