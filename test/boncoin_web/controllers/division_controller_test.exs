defmodule BoncoinWeb.DivisionControllerTest do
  use BoncoinWeb.ConnCase

  alias Boncoin.Contents

  @create_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_bi: "some title_bi", title_en: "some title_en"}
  @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_bi: "some updated title_bi", title_en: "some updated title_en"}
  @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_bi: nil, title_en: nil}

  def fixture(:division) do
    {:ok, division} = Contents.create_division(@create_attrs)
    division
  end

  describe "index" do
    test "lists all divisions", %{conn: conn} do
      conn = get conn, division_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Divisions"
    end
  end

  describe "new division" do
    test "renders form", %{conn: conn} do
      conn = get conn, division_path(conn, :new)
      assert html_response(conn, 200) =~ "New Division"
    end
  end

  describe "create division" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, division_path(conn, :create), division: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == division_path(conn, :show, id)

      conn = get conn, division_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Division"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, division_path(conn, :create), division: @invalid_attrs
      assert html_response(conn, 200) =~ "New Division"
    end
  end

  describe "edit division" do
    setup [:create_division]

    test "renders form for editing chosen division", %{conn: conn, division: division} do
      conn = get conn, division_path(conn, :edit, division)
      assert html_response(conn, 200) =~ "Edit Division"
    end
  end

  describe "update division" do
    setup [:create_division]

    test "redirects when data is valid", %{conn: conn, division: division} do
      conn = put conn, division_path(conn, :update, division), division: @update_attrs
      assert redirected_to(conn) == division_path(conn, :show, division)

      conn = get conn, division_path(conn, :show, division)
      assert html_response(conn, 200) =~ "some updated latitute"
    end

    test "renders errors when data is invalid", %{conn: conn, division: division} do
      conn = put conn, division_path(conn, :update, division), division: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Division"
    end
  end

  describe "delete division" do
    setup [:create_division]

    test "deletes chosen division", %{conn: conn, division: division} do
      conn = delete conn, division_path(conn, :delete, division)
      assert redirected_to(conn) == division_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, division_path(conn, :show, division)
      end
    end
  end

  defp create_division(_) do
    division = fixture(:division)
    {:ok, division: division}
  end
end
