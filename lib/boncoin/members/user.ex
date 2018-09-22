defmodule Boncoin.Members.User do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  import Boncoin.Gettext
  alias Boncoin.Contents.{Announce}
  alias Boncoin.CustomModules

  @derive {Poison.Encoder, only: [:id, :email, :nickname, :phone_number, :viber_active]}

  schema "users" do
    field :uid, :string
    field :email, :string
    field :language, :string, default: "mr"
    field :nickname, :string
    field :member_psw, :string
    field :phone_number, :string
    field :provider, :string
    field :role, :string, default: "MEMBER"
    field :token, :string
    field :token_expiration, :utc_datetime
    field :viber_active, :boolean, default: false
    field :viber_id, :string
    has_many :announces, Announce, on_delete: :delete_all
    has_many :treated_offers, Announce, foreign_key: :treated_by_id, on_delete: :nilify_all
    timestamps()
  end

  @required_fields ~w(nickname phone_number)a
  @optional_fields ~w(language email uid role viber_active viber_id member_psw)a

  @doc false
  def changeset(user, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni([:email, :nickname])
    user
      |> Map.put(:uuid, Ecto.UUID.generate)
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> unique_constraint(:email, message: "Email is already taken")
      |> unique_constraint(:phone_number, message: "Phone number is already taken") # By security
      |> check_guest_phone_number(params)
      |> validate_format(:email, email_regex(), message: "This is not a real email")
      # |> validate_format(:phone_number, phone_regex(), message: "This is not a Myanmar phone number")
      |> validate_inclusion(:provider, ["google"], message: "Oauth provider not supported")
      |> validate_inclusion(:language, ["mr", "my", "en"], message: "Language not supported")
      |> validate_inclusion(:role, ["GUEST", "MEMBER", "ADMIN", "PARTNER", "SUPER"], message: "Role not supported")
      # |> IO.inspect()
  end

  defp check_guest_phone_number(changeset, %{"phone_number" => "09000000000"}) do
      add_error(changeset, :phone_number, "Guest phone number cant post offer")
  end
  defp check_guest_phone_number(changeset, _params) do
      changeset
  end

  def show_errors_in_msg(changeset) do
    case List.first(changeset.errors) do
      {:nickname, _msg} -> gettext("Please check your name or nickname.")
      {:phone_number, {"Guest phone number cant post offer", _}} -> gettext("Please check your phone number.")
      {:title, _msg} -> gettext("Please put a title to your offer.")
      {:price, _msg} -> gettext("Please give a price to your offer.")
      {:description, _msg} -> gettext("Please write a description of your offer.")
      {:photo, _msg} -> gettext("Please post at least one photo.")
      {:email, {"Email is already taken", _}} -> gettext("This email is already used by another user.")
      {:email, {"This is not a real email", _}} -> gettext("This email not a proper email.")
      _ -> # Something else went wrong
        gettext("Sorry we have a technical problem.")
    end
  end

  def phone_regex() do
    ~r/@/
  end

  def email_regex() do
    # ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  end

  def role_select_btn() do
    [guest: "GUEST", member: "MEMBER", admin: "ADMIN", partner: "PARTNER", super: "SUPER"]
  end

  def language_select_btn() do
    [English: "en", Myanmar_Zawgyi: "mr", Myanmar_Unicode: "my"]
  end

  def search_guest_user(query) do
    from u in query,
      where: u.role == "GUEST"
  end

  def filter_admin_users_by_email(query, email) do
    from u in query,
      where: u.email == ^email and u.role in ["SUPER", "ADMIN"]
  end

  def filter_user_by_viber_id(query, viber_id) do
    from u in query,
      where: u.viber_id == ^viber_id
  end

  def filter_user_by_phone_number(query, phone_number) do
    from u in query,
      where: u.phone_number == ^phone_number
  end

  def search_other_user_for_phone_number(query, phone_number) do
    from u in query,
      where: u.phone_number == ^phone_number,
      left_join: a in assoc(u, :announces),
      on: a.status in ["PENDING", "ONLINE"],
      group_by: u.id,
      select: %{id: u.id, viber_active: u.viber_active, nb_announces: count(a.id)}
  end

  def filter_user_public_data(query) do
    from u in query,
      select: %{nickname: u.nickname, email: u.email, phone_number: u.phone_number, viber_active: u.viber_active, role: u.role}
  end

end
