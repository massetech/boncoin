defmodule BoncoinWeb.MainControllerTest do
  use BoncoinWeb.ConnCase
  import Boncoin.Factory
  @moduletag :MainController
  @moduletag :Controller
  # IO.inspect(conn.resp_body, limit: :infinity, printable_limit: :infinity)

  describe "welcome" do
    test "arrives on landing page in EN", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ "Find a good-deal in more than"
    end
    test "shows the right number of public announces", %{conn: conn} do
      insert_list(3, :announce, %{status: "ONLINE"})
      insert_list(2, :announce, %{status: "REFUSED"})
      conn = get conn, "/"
      assert html_response(conn, 200) =~ "more than 3 offers"
    end
    @describetag :locale_my
    test "arrives on landing page in MY", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ "ဈေးနှုန်းသက်သာသောပစ္စည်းပေါင"
    end
    @describetag :locale_dz
    test "arrives on landing page in DZ", %{conn: conn} do
      conn = get conn, "/"
      assert html_response(conn, 200) =~ "ဈေးနှုန်းသက်သာသောပစ္စည်းပေါင"
    end
  end

  describe "conditions" do
    test "arrives on the right page", %{conn: conn} do
      conn = get conn, "/conditions"
      assert html_response(conn, 200) =~ "Our terms of use"
    end
  end

  describe "about" do
    test "arrives on the right page", %{conn: conn} do
      conn = get conn, "/about"
      assert html_response(conn, 200) =~ "About PawChaungKaung"
    end
  end
  @tag :dede
  describe "Viber" do
    test "arrives on the right page", %{conn: conn} do
      conn = conn
        |> Plug.Conn.put_req_header("user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36")
        |> get("/conversations")
      assert html_response(conn, 200) =~ "Connect to PawChaungKaung by Viber or Messenger !"
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
