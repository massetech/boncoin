defmodule Boncoin.Members.User do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  import Boncoin.Gettext
  alias Boncoin.Contents.{Announce}
  alias Boncoin.Members.{Phone}
  alias Boncoin.CustomModules

  # Select only those fields to encode in json the API response
  @derive {Jason.Encoder, only: [:id, :email, :nickname, :phone_number, :bot_active, :bot_provider, :viber_number]}

  schema "users" do
    field :uid, :string
    field :auth_provider, :string
    field :email, :string
    field :active, :boolean, default: true
    field :language, :string, default: "dz"
    field :nickname, :string
    field :member_psw, :string
    field :phone_number, :string
    field :viber_number, :string
    field :messenger_number, :string
    field :role, :string, default: "MEMBER"
    field :token, :string
    field :token_expiration, :utc_datetime
    field :bot_provider, :string
    field :bot_active, :boolean, default: false
    field :bot_id, :string
    has_many :announces, Announce, on_delete: :delete_all
    has_many :phones, Phone, on_delete: :delete_all
    has_many :treated_offers, Announce, foreign_key: :treated_by_id, on_delete: :nilify_all
    timestamps()
  end

  @required_fields ~w(language nickname phone_number role bot_provider bot_active bot_id active)a
  @optional_fields ~w(auth_provider email uid member_psw viber_number)a

  @doc false
  def changeset(user, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni(["nickname"])
    user
      |> Map.put(:uid, Ecto.UUID.generate)
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_format(:email, email_regex(), message: "This is not a real email")
      |> validate_format(:phone_number, phone_regex(), message: "This is not a Myanmar phone number")
      |> validate_format(:viber_number, viber_regex(), message: "This is not a Viber phone number")
      |> validate_inclusion(:auth_provider, ["google"], message: "Oauth provider not supported")
      # |> validate_inclusion(:bot_provider, ["viber", "messenger"], message: "Bot provider not supported")
      # |> validate_inclusion(:language, ["dz", "my", "en"], message: "Language not supported")
      |> validate_inclusion(:role, ["GUEST", "MEMBER", "ADMIN", "PARTNER", "SUPER"], message: "Role not supported")
      |> refuse_guest_phone_number(params)
  end

  defp refuse_guest_phone_number(changeset, %{"phone_number" => "09000000000"}) do
      add_error(changeset, :phone_number, "Guest phone number can't post offer")
  end
  defp refuse_guest_phone_number(changeset, _params) do
      changeset
  end

  def show_errors_in_msg(changeset) do
    case List.first(changeset.errors) do
      {:nickname, _msg} -> dgettext("errors", "Please check your nickname.")
      {:phone_number, {"Guest phone number can't post offer", _}} -> dgettext("errors", "Please check your phone number.")
      {:phone_number, _msg} -> dgettext("errors", "Phone number is already taken.")
      {:viber_number, _msg} -> dgettext("errors", "Viber phone number is not correct (+95....)")
      {:title, _msg} -> dgettext("errors", "Please put a title to your offer (max 50 characters).")
      {:price, _msg} -> dgettext("errors", "Please give a price to your offer.")
      {:description, _msg} -> dgettext("errors", "Please write a description of your offer (max 200 characters).")
      {:conditions, _msg} -> dgettext("errors", "Please accept the conditions.")
      {:bot_active, _} -> dgettext("errors", "Please open a conversation on Viber or Messenger to create an offer.")
      {:photo, _msg} -> dgettext("errors", "Please post at least one photo.")
      {:email, {"Email is already taken", _}} -> dgettext("errors", "This email is already used by another user.")
      {:email, {"This is not a real email", _}} -> dgettext("errors", "This email not a proper email.")
      _ -> # Something else went wrong
        dgettext("errors", "Sorry we have a technical problem..")
    end
  end

  def check_myanmar_phone_number(phone_number) do
    String.match?(phone_number, phone_regex())
  end

  def email_regex() do
    # ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  end
  def phone_regex() do
    ~r/^[0][9]\d{9}$/
    # ~r/^([09]{1})([0-9]{10})$/
  end
  def viber_regex() do
    ~r/^\+[1-9]{1,2}\d{5,10}$/
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

  def filter_super_users(query) do
    from u in query,
      where: u.role in ["SUPER"]
  end

  def filter_active_user_by_bot_id(query, bot_id, provider) do
    from u in query,
      where: u.bot_id == ^bot_id and u.bot_provider == ^provider and u.active == true and u.bot_active == true
  end

  def filter_active_user_by_phone_number(query, phone_number) do
    from u in query,
      where: u.phone_number == ^phone_number and u.active == true
  end

  def filter_user_public_data(query) do
    from u in query,
      select: %{nickname: u.nickname, phone_number: u.phone_number, viber_number: u.viber_number}
  end

end
