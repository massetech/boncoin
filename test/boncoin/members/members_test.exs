defmodule Boncoin.MembersTest do
  use Boncoin.DataCase
  alias Boncoin.Members
  alias Boncoin.Members.User
  import Boncoin.Factory

  describe "users" do
    @valid_attrs %{email: "some_email@gmail.com", language: "en", nickname: "some name", phone_number: "09030303030", bot_active: true, bot_id: "some bot_id"}
    @update_attrs %{email: "some_other_email@gmail.com", language: "mr", nickname: "some updated name", phone_number: "09726272625", bot_active: false, bot_id: "some updated bot_id"}
    @invalid_attrs %{email: nil, language: nil, nickname: nil, password: nil, phone_number: nil, bot_active: nil, bot_id: nil}

    test "list_users/0 returns all users" do
      [user_0, user_1, user_2] = insert_list(3, :user)
      list = Members.list_users()
      assert Enum.count(list, fn x -> x.id == user_0.id end) > 0
      assert Enum.count(list, fn x -> x.id == user_1.id end) > 0
      assert Enum.count(list, fn x -> x.id == user_2.id end) > 0
    end

    test "get_user!/1 returns the user with given id" do
      user = insert(:user)
      assert Members.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Members.create_user(@valid_attrs)
      assert user.email == "some_email@gmail.com"
      assert user.language == "en"
      assert user.nickname == "some name"
      assert user.phone_number == "09030303030"
      assert user.bot_active == true
      assert user.bot_id == "some bot_id"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      assert {:ok, user} = Members.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "some_other_email@gmail.com"
      assert user.language == "mr"
      assert user.nickname == "some updated name"
      assert user.phone_number == "09726272625"
      assert user.bot_active == false
      assert user.bot_id == "some updated bot_id"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = insert(:user)
      assert {:error, %Ecto.Changeset{}} = Members.update_user(user, @invalid_attrs)
      assert user == Members.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Members.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Members.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = insert(:user)
      assert %Ecto.Changeset{} = Members.change_user(user)
    end
  end
end
