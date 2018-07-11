defmodule BoncoinWeb.FamilyControllerTest do
  use BoncoinWeb.ConnCase

  alias Boncoin.Contents

  @create_attrs %{active: true, title_bi: "some title_bi", title_en: "some title_en"}
  @update_attrs %{active: false, title_bi: "some updated title_bi", title_en: "some updated title_en"}
  @invalid_attrs %{active: nil, title_bi: nil, title_en: nil}

  def fixture(:family) do
    {:ok, family} = Contents.create_family(@create_attrs)
    family
  end

  describe "index" do
    test "lists all familys", %{conn: conn} do
      conn = get conn, family_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Familys"
    end
  end

  describe "new family" do
    test "renders form", %{conn: conn} do
      conn = get conn, family_path(conn, :new)
      assert html_response(conn, 200) =~ "New Family"
    end
  end

  describe "create family" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, family_path(conn, :create), family: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == family_path(conn, :show, id)

      conn = get conn, family_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show Family"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, family_path(conn, :create), family: @invalid_attrs
      assert html_response(conn, 200) =~ "New Family"
    end
  end

  describe "edit family" do
    setup [:create_family]

    test "renders form for editing chosen family", %{conn: conn, family: family} do
      conn = get conn, family_path(conn, :edit, family)
      assert html_response(conn, 200) =~ "Edit Family"
    end
  end

  describe "update family" do
    setup [:create_family]

    test "redirects when data is valid", %{conn: conn, family: family} do
      conn = put conn, family_path(conn, :update, family), family: @update_attrs
      assert redirected_to(conn) == family_path(conn, :show, family)

      conn = get conn, family_path(conn, :show, family)
      assert html_response(conn, 200) =~ "some updated title_bi"
    end

    test "renders errors when data is invalid", %{conn: conn, family: family} do
      conn = put conn, family_path(conn, :update, family), family: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Family"
    end
  end

  describe "delete family" do
    setup [:create_family]

    test "deletes chosen family", %{conn: conn, family: family} do
      conn = delete conn, family_path(conn, :delete, family)
      assert redirected_to(conn) == family_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, family_path(conn, :show, family)
      end
    end
  end

  defp create_family(_) do
    family = fixture(:family)
    {:ok, family: family}
  end
end
