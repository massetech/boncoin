defmodule Boncoin.MembersTest do
  use Boncoin.DataCase
  alias Boncoin.Members
  alias Boncoin.Members.{User, Conversation}
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

  describe "conversations" do
    @valid_attrs %{bot_provider: "viber", psid: "some psid", scope: "some scope"}
    @update_attrs %{bot_provider: "viber", psid: "some updated psid", scope: "some updated scope"}
    @invalid_attrs %{bot_provider: nil, psid: nil, scope: nil}

    # def conversation_fixture(attrs \\ %{}) do
    #   {:ok, conversation} =
    #     attrs
    #     |> Enum.into(@valid_attrs)
    #     |> Members.create_conversation()
    #
    #   conversation
    # end
    #
    # test "list_conversations/0 returns all conversations" do
    #   conversation = conversation_fixture()
    #   assert Members.list_conversations() == [conversation]
    # end
    #
    # test "get_conversation!/1 returns the conversation with given id" do
    #   conversation = conversation_fixture()
    #   assert Members.get_conversation!(conversation.id) == conversation
    # end
    #
    # test "create_conversation/1 with valid data creates a conversation" do
    #   assert {:ok, %Conversation{} = conversation} = Members.create_conversation(@valid_attrs)
    #   assert conversation.bot_provider == "some bot_provider"
    #   assert conversation.psid == "some psid"
    #   assert conversation.scope == "some scope"
    # end
    #
    # test "create_conversation/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Members.create_conversation(@invalid_attrs)
    # end
    #
    test "update_conversation/2 with valid data updates the conversation" do
      conversation = insert(:conversation)
      assert {:ok, conversation} = Members.update_conversation(conversation, @update_attrs)
      assert %Conversation{} = conversation
      assert conversation.bot_provider == "viber"
      assert conversation.psid == "some updated psid"
      assert conversation.scope == "some updated scope"
    end

    test "update_conversation/2 with invalid data returns error changeset" do
      conversation = insert(:conversation)
      assert {:error, %Ecto.Changeset{}} = Members.update_conversation(conversation, @invalid_attrs)
      assert conversation == Members.get_conversation!(conversation.id)
    end

    test "delete_conversation/1 deletes the conversation" do
      conversation = insert(:conversation)
      assert {:ok, %Conversation{}} = Members.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Members.get_conversation!(conversation.id) end
    end

    # test "change_conversation/1 returns a conversation changeset" do
    #   conversation = conversation_fixture()
    #   assert %Ecto.Changeset{} = Members.change_conversation(conversation)
    # end
  end

  describe "pubs" do
    alias Boncoin.Members.Pub

    @valid_attrs %{end_date: "2010-04-17 14:00:00.000000Z", language: "some language", link: "some link", nb_click: 42, nb_view: 42, priority: 42, start_date: "2010-04-17 14:00:00.000000Z", title: "some title"}
    @update_attrs %{end_date: "2011-05-18 15:01:01.000000Z", language: "some updated language", link: "some updated link", nb_click: 43, nb_view: 43, priority: 43, start_date: "2011-05-18 15:01:01.000000Z", title: "some updated title"}
    @invalid_attrs %{end_date: nil, language: nil, link: nil, nb_click: nil, nb_view: nil, priority: nil, start_date: nil, title: nil}

    def pub_fixture(attrs \\ %{}) do
      {:ok, pub} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Members.create_pub()

      pub
    end

    test "list_pubs/0 returns all pubs" do
      pub = pub_fixture()
      assert Members.list_pubs() == [pub]
    end

    test "get_pub!/1 returns the pub with given id" do
      pub = pub_fixture()
      assert Members.get_pub!(pub.id) == pub
    end

    test "create_pub/1 with valid data creates a pub" do
      assert {:ok, %Pub{} = pub} = Members.create_pub(@valid_attrs)
      assert pub.end_date == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert pub.language == "some language"
      assert pub.link == "some link"
      assert pub.nb_click == 42
      assert pub.nb_view == 42
      assert pub.priority == 42
      assert pub.start_date == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
      assert pub.title == "some title"
    end

    test "create_pub/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.create_pub(@invalid_attrs)
    end

    test "update_pub/2 with valid data updates the pub" do
      pub = pub_fixture()
      assert {:ok, pub} = Members.update_pub(pub, @update_attrs)
      assert %Pub{} = pub
      assert pub.end_date == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert pub.language == "some updated language"
      assert pub.link == "some updated link"
      assert pub.nb_click == 43
      assert pub.nb_view == 43
      assert pub.priority == 43
      assert pub.start_date == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert pub.title == "some updated title"
    end

    test "update_pub/2 with invalid data returns error changeset" do
      pub = pub_fixture()
      assert {:error, %Ecto.Changeset{}} = Members.update_pub(pub, @invalid_attrs)
      assert pub == Members.get_pub!(pub.id)
    end

    test "delete_pub/1 deletes the pub" do
      pub = pub_fixture()
      assert {:ok, %Pub{}} = Members.delete_pub(pub)
      assert_raise Ecto.NoResultsError, fn -> Members.get_pub!(pub.id) end
    end

    test "change_pub/1 returns a pub changeset" do
      pub = pub_fixture()
      assert %Ecto.Changeset{} = Members.change_pub(pub)
    end
  end
end
