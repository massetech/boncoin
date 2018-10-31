defmodule Boncoin.Members do
  import Ecto.Query, warn: false
  import Mockery.Macro
  alias Boncoin.{Repo, Contents, ViberApi, MessengerApi}
  alias Boncoin.Members.{User, Conversation}
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
    end
  end

  def get_or_initialize_user_by_phone_number(phone_number) do
    case get_active_user_by_phone_number(phone_number) do
      nil -> {:new_user, %User{}}
      user -> {:ok, user}
    end
  end

  def create_user(attrs \\ %{}) do
    %User{}
      |> User.changeset(attrs)
      |> Repo.insert()
  end

  def create_user_announce(%{"phone_number" => phone_number} = params) do
    user = case get_active_user_by_phone_number(phone_number) do
      nil -> create_user(params)
      user -> update_user(user, params) # Guest user pass by here
    end
    case user do
      {:ok, user} -> Contents.create_announce(params["announces"]["0"], user.id)
      error_user -> error_user
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
      [] ->
        delete_user_conversation(user.bot_provider, user.bot_id)
        update_user(user, %{bot_active: false})
      offers -> {:not_allowed, Enum.count(offers)}
    end
  end

  def link_bot_id_to_phone_number(bot_id, phone_number, user_name, language) do
    params = %{phone_number: phone_number, bot_id: bot_id, nickname: user_name, language: language}
    case get_active_user_by_phone_number(phone_number) do
      nil -> create_user(params) # This phone number is not yet known
      user -> # This phone number is known
        cond do
          user.bot_active == false -> # This phone number is not yet linked to a bot
            update_user(user, params)
          user.bot_active == true && user.phone_number == params.phone_number -> # This phone number is linked to this bot and has to be changed
            {:error, params} # Might be a problem here
        end
        params = case user.bot_active do # This number is already used
          true -> %{bot_id: bot_id, language: language, nickname: user_name}
          # This number was not yet connected to a bot
          false -> %{bot_id: bot_id, language: language, bot_active: true, nickname: user_name}
        end
        case update_user(user, params) do
          {:ok, _} -> {:updated, params}
          [:error, _] -> {:error, params}
        end
    end
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  # -------------------------------- CONVERSATION ----------------------------------------

  def get_conversation_by_provider_psid(bot_provider, psid) do
    case Repo.get_by(Conversation, psid: psid) do
      nil -> nil
      conversation ->
        # Check if PSID is the same for Viber and Messenger
        if conversation.bot_provider == bot_provider do
          conversation
        else
          nil
        end
    end
  end

  def get_actual_conversation_by_provider_psid(bot_provider, psid) do
    case get_conversation_by_provider_psid(bot_provider, psid) do
      nil -> %{scope: "welcome", nickname: ""} # Fallback if no conversation found
      conversation -> conversation
    end
  end

  def create_or_update_conversation(%{bot_provider: bot_provider, psid: psid} = params) do
    case get_conversation_by_provider_psid(bot_provider, psid) do
      nil -> create_conversation(params)
      conversation -> update_conversation(conversation, params) |> IO.inspect()
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

  def delete_user_conversation(bot_provider, bot_id) do
    case get_conversation_by_provider_psid(bot_provider, bot_id) do
      nil -> nil
      conversation -> delete_conversation(conversation)
    end
  end

  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  def change_conversation(%Conversation{} = conversation) do
    Conversation.changeset(conversation, %{})
  end

  alias Boncoin.Members.Pub

  @doc """
  Returns the list of pubs.

  ## Examples

      iex> list_pubs()
      [%Pub{}, ...]

  """
  def list_pubs do
    Repo.all(Pub)
  end

  @doc """
  Gets a single pub.

  Raises `Ecto.NoResultsError` if the Pub does not exist.

  ## Examples

      iex> get_pub!(123)
      %Pub{}

      iex> get_pub!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pub!(id), do: Repo.get!(Pub, id)

  @doc """
  Creates a pub.

  ## Examples

      iex> create_pub(%{field: value})
      {:ok, %Pub{}}

      iex> create_pub(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pub(attrs \\ %{}) do
    %Pub{}
    |> Pub.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pub.

  ## Examples

      iex> update_pub(pub, %{field: new_value})
      {:ok, %Pub{}}

      iex> update_pub(pub, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pub(%Pub{} = pub, attrs) do
    pub
    |> Pub.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Pub.

  ## Examples

      iex> delete_pub(pub)
      {:ok, %Pub{}}

      iex> delete_pub(pub)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pub(%Pub{} = pub) do
    Repo.delete(pub)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pub changes.

  ## Examples

      iex> change_pub(pub)
      %Ecto.Changeset{source: %Pub{}}

  """
  def change_pub(%Pub{} = pub) do
    Pub.changeset(pub, %{})
  end
end
