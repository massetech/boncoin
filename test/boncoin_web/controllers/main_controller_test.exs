defmodule BoncoinWeb.MainControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory
  @moduletag :MainController
  @moduletag :Controller

  describe "welcome" do
    test "arrives on landing page" do
      conn = get build_conn(), "/"
      assert html_response(conn, 200) =~ "Welcome"
    end
    test "shows the right number of public announces" do
      insert_list(3, :announce, %{status: "ONLINE"})
      insert_list(2, :announce, %{status: "REFUSED"})
      conn = get build_conn(), "/"
      assert html_response(conn, 200) =~ "more than 3offers"
    end
  end

  describe "conditions" do
    test "arrives on the right page" do
      conn = get build_conn(), "/conditions"
      assert html_response(conn, 200) =~ "Our terms of use"
    end
  end

  describe "about" do
    test "arrives on the right page" do
      conn = get build_conn(), "/about"
      assert html_response(conn, 200) =~ "About PawChaungKaung"
    end
  end

  describe "Viber" do
    test "arrives on the right page" do
      conn = get build_conn(), "/viber"
      assert html_response(conn, 200) =~ "Connect your Viber app"
    end
  end

  describe "dashboard" do
    @tag :admin_authenticated
    test "arrives on the right page for admin user", %{conn: conn} do
      conn = get conn, "/admin/dashboard"
      assert html_response(conn, 200) =~ "Dashboard"
    end

    @tag :member_authenticated
    test "returns on landing page for non admin user", %{conn: conn} do
      conn = get conn, "/admin/dashboard"
      assert html_response(conn, 308)
      assert get_flash(conn, :alert) == "You must be admin to access that part."
    end

    test "returns on landing page for non authenticated user", %{conn: conn} do
      conn = get conn, "/admin/dashboard"
      assert html_response(conn, 308)
      assert get_flash(conn, :alert) == "You must be logged in to access that part."
    end
  end

end
