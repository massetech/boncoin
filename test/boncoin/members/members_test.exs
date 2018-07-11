defmodule Boncoin.MembersTest do
  use Boncoin.DataCase

  alias Boncoin.Members

  describe "users" do
    alias Boncoin.Members.User

    @valid_attrs %{email: "some email", language: "some language", name: "some name", password: "some password", phone_number: "some phone_number", provider: "some provider", role: "some role", token: "some token", token_expiration: "2010-04-17 14:00:00.000000Z", viber_active: true, viber_id: "some viber_id"}
    @update_attrs %{email: "some updated email", language: "some updated language", name: "some updated name", password: "some updated password", phone_number: "some updated phone_number", provider: "some updated provider", role: "some updated role", token: "some updated token", token_expiration: "2011-05-18 15:01:01.000000Z", viber_active: false, viber_id: "some updated viber_id"}
    @invalid_attrs %{email: nil, language: nil, name: nil, password: nil, phone_number: nil, provider: nil, role: nil, token: nil, token_expiration: nil, viber_active: nil, viber_id: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Members.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Members.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Members.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Members.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.language == "some language"
      assert user.name == "some name"
      assert user.password == "some password"
      assert user.phone_number == "some phone_number"
      assert user.provider == "some provider"
      assert user.role == "some role"
      assert user.token == "some token"
      assert user.token_expiration == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert user.viber_active == true
      assert user.viber_id == "some viber_id"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, user} = Members.update_user(user, @update_attrs)
      assert %User{} = user
      assert user.email == "some updated email"
      assert user.language == "some updated language"
      assert user.name == "some updated name"
      assert user.password == "some updated password"
      assert user.phone_number == "some updated phone_number"
      assert user.provider == "some updated provider"
      assert user.role == "some updated role"
      assert user.token == "some updated token"
      assert user.token_expiration == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert user.viber_active == false
      assert user.viber_id == "some updated viber_id"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Members.update_user(user, @invalid_attrs)
      assert user == Members.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Members.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Members.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Members.change_user(user)
    end
  end
end
