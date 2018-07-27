defmodule Boncoin.Members do

  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false
  alias Boncoin.Repo
  alias Boncoin.Members.User
  alias Ueberauth.Auth

  # -------------------------------- UEBERAUTH ----------------------------------------
  # QUERIES ------------------------------------------------------------------
  # METHODS ------------------------------------------------------------------
  def sign_in_user(%Auth{} = auth) do
    user = email_from_auth(auth)
      |> check_admin_email()
      |> IO.inspect()
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
  # QUERIES ------------------------------------------------------------------
  defp filter_admin_users_by_email(query \\ User, email) do
    from u in User,
      where: u.email == ^email and u.role in ["SUPER", "ADMIN"]
  end

  defp filter_user_by_viber_id(query \\ User, viber_id) do
    from u in User,
      where: u.viber_id == ^viber_id
  end

  defp filter_user_by_phone_number(query \\ User, phone_number) do
    from u in User,
      where: u.phone_number == ^phone_number
  end

  defp search_other_user_for_phone_number(query \\ User, phone_number) do
    from u in User,
      where: u.phone_number == ^phone_number,
      left_join: a in assoc(u, :announces),
      on: a.status in ["PENDING", "ONLINE"],
      group_by: u.id,
      select: %{id: u.id, viber_active: u.viber_active, nb_announces: count(a.id)}
  end

  def filter_user_public_data(query \\ User) do
    from u in User,
      # select: map(u, [:nickname, :email, :phone_number])
      select: %{nickname: u.nickname, email: u.email, phone_number: u.phone_number, viber_active: u.viber_active, role: u.role}
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Checks if an email is ADMIN or USER.
  """

  defp check_admin_email(email) do
    User
    |> filter_admin_users_by_email(email)
    |> Repo.one()
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Reads the data known for a phone number.
  """

  def get_user_by_phone_number(phone_number) do
    User
      |> filter_user_by_phone_number(phone_number)
      |> Repo.one()
  end

  def get_other_user_by_phone_number(phone_number)do
    Uers
      |> search_other_user_for_phone_number(phone_number)
      |> Repo.one()
  end

  def get_user_by_viber_id(viber_id) do
    User
    |> filter_user_by_viber_id(viber_id)
    |> Repo.one()
  end

  def get_user_or_create_by_phone_number(phone_number) do
    case get_user_by_phone_number(phone_number) do
      nil ->
        case create_user(%{phone_number: phone_number}) do
          {:ok, user} -> user
          _ -> nil
        end
      user -> user
    end
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def link_viber_id_to_phone_number(viber_id, phone_number, user_name, language) do
    params = %{phone_number: phone_number, viber_id: viber_id, nickname: user_name, language: language}
    case get_user_by_phone_number(phone_number) do
      nil -> create_user(params) # This phone number is not yet known
      user -> # This phone number is known
        cond do
          user.viber_active == false -> # This phone number is not yet linked to viber
            update_user(user, params)
          user.viber_active == true && user.phone_number == params.phone_number -> # This phone number is linked to this viber and has to be changed
            # Delete
        end
        case user.viber_active do # This number is already used
          true -> params = %{viber_id: viber_id, language: language, nickname: user_name}
          # This number was not yet connected to viber
          false -> params = %{viber_id: viber_id, language: language, viber_active: true, nickname: user_name}
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
end
