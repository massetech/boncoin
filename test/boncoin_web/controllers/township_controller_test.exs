defmodule BoncoinWeb.TownshipControllerTest do
  use BoncoinWeb.ConnCase

  alias Boncoin.Contents

  @create_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_bi: "some title_bi", title_en: "some title_en"}
  @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_bi: "some updated title_bi", title_en: "some updated title_en"}
  @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_bi: nil, title_en: nil}

  def fixture(:township) do
    {:ok, township} = Contents.create_township(@create_attrs)
    township
  end

  describe "index" do
    test "lists all townships", %{conn: conn} do
      conn = get conn, township_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Townships"
    end
  end

  describe "new township" do
    test "renders form", %{conn: conn} do
      conn = get conn, township_path(conn, :new)
      assert html_response(conn, 200) =~ "New Township"
    end
  end

  describe "create township" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, township_path(conn, :create), township: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == township_path(conn, :show, id)

      conn = get conn, township_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Township"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, township_path(conn, :create), township: @invalid_attrs
      assert html_response(conn, 200) =~ "New Township"
    end
  end

  describe "edit township" do
    setup [:create_township]

    test "renders form for editing chosen township", %{conn: conn, township: township} do
      conn = get conn, township_path(conn, :edit, township)
      assert html_response(conn, 200) =~ "Edit Township"
    end
  end

  describe "update township" do
    setup [:create_township]

    test "redirects when data is valid", %{conn: conn, township: township} do
      conn = put conn, township_path(conn, :update, township), township: @update_attrs
      assert redirected_to(conn) == township_path(conn, :show, township)

      conn = get conn, township_path(conn, :show, township)
      assert html_response(conn, 200) =~ "some updated latitute"
    end

    test "renders errors when data is invalid", %{conn: conn, township: township} do
      conn = put conn, township_path(conn, :update, township), township: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Township"
    end
  end

  describe "delete township" do
    setup [:create_township]

    test "deletes chosen township", %{conn: conn, township: township} do
      conn = delete conn, township_path(conn, :delete, township)
      assert redirected_to(conn) == township_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, township_path(conn, :show, township)
      end
    end
  end

  defp create_township(_) do
    township = fixture(:township)
    {:ok, township: township}
  end
end
