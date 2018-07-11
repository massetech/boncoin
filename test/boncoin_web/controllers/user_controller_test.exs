defmodule BoncoinWeb.UserControllerTest do
  use BoncoinWeb.ConnCase

  alias Boncoin.Members

  @create_attrs %{email: "some email", language: "some language", name: "some name", password: "some password", phone_number: "some phone_number", provider: "some provider", role: "some role", token: "some token", token_expiration: "2010-04-17 14:00:00.000000Z", viber_active: true, viber_id: "some viber_id"}
  @update_attrs %{email: "some updated email", language: "some updated language", name: "some updated name", password: "some updated password", phone_number: "some updated phone_number", provider: "some updated provider", role: "some updated role", token: "some updated token", token_expiration: "2011-05-18 15:01:01.000000Z", viber_active: false, viber_id: "some updated viber_id"}
  @invalid_attrs %{email: nil, language: nil, name: nil, password: nil, phone_number: nil, provider: nil, role: nil, token: nil, token_expiration: nil, viber_active: nil, viber_id: nil}

  def fixture(:user) do
    {:ok, user} = Members.create_user(@create_attrs)
    user
  end

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get conn, user_path(conn, :index)
      assert html_response(conn, 200) =~ "Listing Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get conn, user_path(conn, :new)
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == user_path(conn, :show, id)

      conn = get conn, user_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Show User"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @invalid_attrs
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    setup [:create_user]

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get conn, user_path(conn, :edit, user)
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    setup [:create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put conn, user_path(conn, :update, user), user: @update_attrs
      assert redirected_to(conn) == user_path(conn, :show, user)

      conn = get conn, user_path(conn, :show, user)
      assert html_response(conn, 200) =~ "some updated email"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "delete user" do
    setup [:create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete conn, user_path(conn, :delete, user)
      assert redirected_to(conn) == user_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, user_path(conn, :show, user)
      end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
