defmodule BoncoinWeb.AnnounceControllerTest do
  use BoncoinWeb.ConnCase

  alias Boncoin.Contents

  @create_attrs %{conditions: true, description: "some description", language: "some language", latitute: "some latitute", longitude: "some longitude", photo1: "some photo1", photo2: "some photo2", photo3: "some photo3", price: 120.5, status: "some status", title: "some title", validity_date: "2010-04-17 14:00:00.000000Z"}
  @update_attrs %{conditions: false, description: "some updated description", language: "some updated language", latitute: "some updated latitute", longitude: "some updated longitude", photo1: "some updated photo1", photo2: "some updated photo2", photo3: "some updated photo3", price: 456.7, status: "some updated status", title: "some updated title", validity_date: "2011-05-18 15:01:01.000000Z"}
  @invalid_attrs %{conditions: nil, description: nil, language: nil, latitute: nil, longitude: nil, photo1: nil, photo2: nil, photo3: nil, price: nil, status: nil, title: nil, validity_date: nil}

  def fixture(:announce) do
    {:ok, announce} = Contents.create_announce(@create_attrs)
    announce
  end

  describe "index" do
    test "lists all announces", %{conn: conn} do
      conn = get conn, announce_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Announces"
    end
  end

  describe "new announce" do
    test "renders form", %{conn: conn} do
      conn = get conn, announce_path(conn, :new)
      assert html_response(conn, 200) =~ "New Announce"
    end
  end

  describe "create announce" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, announce_path(conn, :create), announce: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == announce_path(conn, :show, id)

      conn = get conn, announce_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Announce"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, announce_path(conn, :create), announce: @invalid_attrs
      assert html_response(conn, 200) =~ "New Announce"
    end
  end

  describe "edit announce" do
    setup [:create_announce]

    test "renders form for editing chosen announce", %{conn: conn, announce: announce} do
      conn = get conn, announce_path(conn, :edit, announce)
      assert html_response(conn, 200) =~ "Edit Announce"
    end
  end

  describe "update announce" do
    setup [:create_announce]

    test "redirects when data is valid", %{conn: conn, announce: announce} do
      conn = put conn, announce_path(conn, :update, announce), announce: @update_attrs
      assert redirected_to(conn) == announce_path(conn, :show, announce)

      conn = get conn, announce_path(conn, :show, announce)
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, announce: announce} do
      conn = put conn, announce_path(conn, :update, announce), announce: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Announce"
    end
  end

  describe "delete announce" do
    setup [:create_announce]

    test "deletes chosen announce", %{conn: conn, announce: announce} do
      conn = delete conn, announce_path(conn, :delete, announce)
      assert redirected_to(conn) == announce_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, announce_path(conn, :show, announce)
      end
    end
  end

  defp create_announce(_) do
    announce = fixture(:announce)
    {:ok, announce: announce}
  end
end
