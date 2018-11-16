defmodule Boncoin.Members do
  import Ecto.Query, warn: false
  import Mockery.Macro
  alias Boncoin.{Repo, Contents, ViberApi, MessengerApi}
  alias Boncoin.Members.{User, Conversation, Phone, Pub}
  alias Ueberauth.Auth

  # -------------------------------- UEBERAUTH ----------------------------------------

  def sign_in_user(%Auth{} = auth) do
    user = email_from_auth(auth) |> check_admin_email()
    case user do
      nil -> {:error, "User not allowed to log in as admin"}
      user -> update_user(user, basic_info(auth))
    end
  end

  defp basic_info(auth) do
    %{uid: auth.uid, token: token_from_auth(auth), token_expiration: exp_token_from_auth(auth),
      provider: Atom.to_string(auth.provider), email: email_from_auth(auth)}
  end

  defp token_from_auth(%{credentials: %{token: token}}), do: token
  defp exp_token_from_auth(%{credentials: %{expires_at: exp}}) do
    Timex.shift(Timex.now, seconds: exp)  # Google announces seconds
  end

  defp email_from_auth(%{info: %{email: email}}), do: email

  # -------------------------------- USER ----------------------------------------

  def send_bot_message_to_user(bot_results, user) do
    case user.bot_provider do
      "viber" ->
        # IO.puts("Message sent to user by Viber")
        Enum.map(bot_results.messages, fn msg -> mockable(ViberApi).send_message(user.bot_id, msg) end)
        {:ok, "message sent to user by Viber", bot_results.messages}
      "messenger" ->
        # IO.puts("Message sent to user by Messenger")
        Enum.map(bot_results.messages, fn msg -> mockable(MessengerApi).send_message(user.bot_id, msg) end)
        {:ok, "message sent to user by Messenger", bot_results.messages}
      _ -> {:error, "message not sent, bot not recognized", bot_results.messages}
    end
  end

  defp check_admin_email(email) do
    User
      |> User.filter_admin_users_by_email(email)
      |> Repo.one()
  end

  def list_users do
    User
      |> Repo.all()
      |> Repo.preload(:announces)
  end

  def read_phone_details(phone_number) do
    case User.check_myanmar_phone_number(phone_number) do
      true ->
        get_or_initialize_user_by_phone_number(phone_number)
      false ->
        {:error, "wrong Myanmar phone number"}
    end
  end

  def get_guest_user() do
    User
      |> User.search_guest_user()
      |> Repo.all()
      |> List.first()
  end

  def admin_user? (user) do
    if Enum.member?(["ADMIN", "SUPER"], user.role) do
      true
    else
      false
    end
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_active_user_by_phone_number(phone_number) do
    User
      |> User.filter_active_user_by_phone_number(phone_number)
      |> Repo.one()
      |> Repo.preload(:announces)
  end

  def get_active_user_by_bot_id(bot_id, provider) do
    case bot_id do
      nil -> nil
      bot_id ->
        User
          |> User.filter_active_user_by_bot_id(bot_id, provider)
          |> Repo.one()
          |> Repo.preload(:announces)
    end
  end

  def get_or_initialize_user_by_phone_number(phone_number) do
    case get_active_user_by_phone_number(phone_number) do
      nil -> {:new_user, %User{}}
      user -> {:ok, user}
    end
  end

  def create_and_track_user(user_params) do
    case create_user(user_params) do
      {:ok, user} -> create_phone(user)
      {:error, changeset} -> {:error, changeset}
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
  end

  def create_user_announce(%{"phone_number" => phone_number} = params) do
    user = case get_active_user_by_phone_number(phone_number) do
      nil -> create_and_track_user(params)
      user -> udpate_and_track_user(user, params) # Guest user pass by here
    end
    case user do
      {:ok, user} -> Contents.create_announce(params["announces"]["0"], user.id)
      error_user -> error_user
    end
  end

  def udpate_and_track_user(user, attrs) do
    case update_user(user, attrs) do
      {:ok, user} -> update_phone(user)
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_user(%User{} = user, attrs) do
    user
      |> User.changeset(attrs)
      |> Repo.update()
  end

  def permission_to_quit_bot(user) do
    case Contents.get_user_active_offers(user) do
      [] -> {:ok, "User allowed to quit bot"}
      offers -> {:not_allowed, Enum.count(offers)}
    end
  end

  def remove_bot(user) do
    case Contents.get_user_active_offers(user) do
      [] -> udpate_and_track_user(user, %{bot_active: false})
      offers -> {:not_allowed, Enum.count(offers)}
    end
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  # -------------------------------- CONVERSATION ----------------------------------------

  def get_conversation_by_provider_psid(bot_provider, psid) do
    Conversation
      |> Conversation.filter_conversation_by_bot(bot_provider, psid)
      |> Repo.one()
  end

  def get_or_initiate_conversation(bot_provider, psid, nickname) do
    # Initiate the conversation for the first visit
    conv_params = %{scope: "welcome", bot_provider: bot_provider, psid: psid, nickname: nickname}
    case get_conversation_by_provider_psid(bot_provider, psid) do
      nil ->
        case create_conversation(conv_params) do
          {:ok, conversation} -> conversation
          error -> error
        end
      conversation -> conversation
    end
  end

  def get_conversation!(id), do: Repo.get!(Conversation, id)

  def create_conversation(attrs \\ %{}) do
    %Conversation{}
      |> Conversation.changeset(attrs)
      |> Repo.insert()
  end

  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
      |> Conversation.changeset(attrs)
      |> Repo.update()
  end

  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  def change_conversation(%Conversation{} = conversation) do
    Conversation.changeset(conversation, %{})
  end

  # -------------------------------- PUB ----------------------------------------

  def list_pubs do
    Repo.all(Pub)
  end

  def get_pub!(id), do: Repo.get!(Pub, id)

  def create_pub(attrs \\ %{}) do
    %Pub{}
    |> Pub.changeset(attrs)
    |> Repo.insert()
  end

  def update_pub(%Pub{} = pub, attrs) do
    pub
    |> Pub.changeset(attrs)
    |> Repo.update()
  end

  def delete_pub(%Pub{} = pub) do
    Repo.delete(pub)
  end

  def change_pub(%Pub{} = pub) do
    Pub.changeset(pub, %{})
  end

  # -------------------------------- PHONE ----------------------------------------

  def list_phones do
    Repo.all(Phone)
  end

  def get_phone!(id), do: Repo.get!(Phone, id)


  def get_active_phone_by_user_id(user_id) do
    Phone
      |> Phone.search_active_phone_for_user(user_id)
      |> Repo.one()
  end

  def get_active_phone_by_phone_number(phone_number) do
    Phone
      |> Phone.search_active_phone_for_phone_number(phone_number)
      |> Repo.one()
  end

  def get_phones_by_user_id(user_id) do
    # Function only used for tests !!!!! (many response possible for a user...)
    Phone
      |> Phone.search_phones_for_user(user_id)
      |> Repo.all()
  end

  def create_phone(user) do
    # Unactive the old phone number if it exists
    case get_active_phone_by_phone_number(user.phone_number) do
      nil -> nil
      phone_tracking -> unactive_phone_tracking(phone_tracking)
    end
    # Create the new phone number tracking
    %Phone{}
      |> Phone.changeset(%{user_id: user.id, phone_number: user.phone_number, active: true, creation_date: Timex.now()})
      |> Repo.insert()
    {:ok, user}
  end

  def update_phone(user) do
    phone_tracking = get_active_phone_by_user_id(user.id)
    cond do
      phone_tracking == nil -> create_phone(user)
      phone_tracking.phone_number == user.phone_number -> {:ok, user}
      phone_tracking.phone_number != user.phone_number ->
        unactive_phone_tracking(phone_tracking)
        create_phone(user)
    end
  end

  defp unactive_phone_tracking(phone_tracking) do
    phone_tracking
      |> Phone.changeset(%{active: false, closing_date: Timex.now()})
      |> Repo.update()
  end

  def delete_phone(%Phone{} = phone) do
    Repo.delete(phone)
  end

  def change_phone(%Phone{} = phone) do
    Phone.changeset(phone, %{})
  end
end
