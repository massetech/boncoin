defmodule BoncoinWeb.UserControllerTest do
  use BoncoinWeb.ConnCase
  alias Boncoin.Members
  import Boncoin.Factory

  @create_attrs %{email: "some_email@gmail.com", language: "en", nickname: "some name", phone_number: "09010101010", role: "MEMBER", token: "some token", viber_active: true, bot_provider: "viber", bot_id: "bot_id"}
  @update_attrs %{email: "another_email@gmail.com", language: "my", nickname: "some updated name", phone_number: "09020202020", role: "ADMIN", token: "some updated token", viber_active: false, bot_provider: "viber", bot_id: "bot_id"}
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

  # describe "new user" do
  #   test "renders form", %{conn: conn} do
  #     conn = get conn, user_path(conn, :new)
  #     assert html_response(conn, 200) =~ "New user"
  #   end
  # end

  describe "edit user" do
    test "renders form", %{conn: conn} do
      user = insert(:user)
      conn = get conn, user_path(conn, :edit, user)
      assert html_response(conn, 200) =~ "Edit user"
    end
  end

  # describe "create user" do
  #   test "redirects to index when data is valid", %{conn: conn} do
  #     conn = post conn, user_path(conn, :create), user: @create_attrs
  #     assert html_response(conn, 302)
  #     assert get_flash(conn, :info) == "User created successfully."
  #   end
  #   test "renders errors when data is invalid", %{conn: conn} do
  #     conn = post conn, user_path(conn, :create), user: @invalid_attrs
  #     assert html_response(conn, 200) =~ "Errors, please check."
  #     assert html_response(conn, 200) =~ "New user"
  #   end
  # end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn} do
      user = insert(:user)
      conn = delete conn, user_path(conn, :delete, user)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "User deleted successfully."
    end
  end

  describe "new user announce" do
    test "renders form", %{conn: conn} do
      conn = get conn, user_path(conn, :new_user_announce)
      assert html_response(conn, 200) =~ "Fill your details"
    end
  end

end
