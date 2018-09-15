defmodule BoncoinWeb.UserControllerTest do
  use BoncoinWeb.ConnCase
  alias Boncoin.Members
  import Boncoin.Factory

  @create_attrs %{email: "some email", language: "en", nickname: "some name", phone_number: "09010101010", role: "MEMBER", token: "some token", viber_active: true}
  @update_attrs %{email: "some updated email", language: "my", nickname: "some updated name", phone_number: "09020202020", role: "ADMIN", token: "some updated token", viber_active: false}
  @invalid_attrs %{email: nil, language: nil, nickname: nil, phone_number: nil}
  @moduletag :admin_authenticated
  @moduletag :UserController
  @moduletag :Controller

  describe "index" do
    test "lists all users", %{conn: conn} do
      conn = get conn, user_path(conn, :index)
      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get conn, user_path(conn, :new)
      assert html_response(conn, 200) =~ "New user"
    end
  end

  describe "create user" do
    test "redirects to index when data is valid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @create_attrs
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "User created successfully."
    end
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, user_path(conn, :create), user: @invalid_attrs
      assert html_response(conn, 200) =~ "Errors, please check."
      assert html_response(conn, 200) =~ "New user"
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn} do
      user = insert(:user)
      conn = delete conn, user_path(conn, :delete, user)
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "USer deleted successfully."
    end
  end

end
