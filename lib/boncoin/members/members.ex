defmodule Boncoin.Members do
  import Ecto.Query, warn: false
  alias Boncoin.{Repo, ViberApi, Contents}
  alias Boncoin.Members.User
  alias Ueberauth.Auth
  alias BoncoinWeb.ViberController

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
    cond do
      String.match?(phone_number, ~r/^([09]{1})([0-9]{10})$/) -> # The number is a Myanmar mobile number
        get_or_initialize_user_by_phone_number(phone_number)
      true -> # The number is a NOT a Myanmar mobile number
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

  # def get_other_user_by_phone_number(phone_number)do
  #   User
  #     |> User.search_other_user_for_phone_number(phone_number)
  #     |> Repo.one()
  # end

  def get_user_by_bot_id(bot_id, provider) do
    User
      |> User.filter_user_by_bot_id(bot_id, provider)
      |> Repo.one()
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
      [] -> update_user(user, %{active: false, bot_active: false})
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
            # Delete
        end
        case user.bot_active do # This number is already used
          true -> params = %{bot_id: bot_id, language: language, nickname: user_name}
          # This number was not yet connected to a bot
          false -> params = %{bot_id: bot_id, language: language, bot_active: true, nickname: user_name}
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
