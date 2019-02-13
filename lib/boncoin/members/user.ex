defmodule Boncoin.Members.User do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  import Boncoin.Gettext
  alias Boncoin.Contents.{Announce}
  alias Boncoin.Members.{Phone, Conversation}
  alias Boncoin.CustomModules

  # Select only those fields to encode in json the API response
  @derive {Jason.Encoder, only: [:id, :phone_number, :nickname, :viber_number, :conversation]}

  schema "users" do
    field :uid, :string
    field :auth_provider, :string
    field :email, :string
    field :active, :boolean, default: true
    field :language, :string, default: "dz"
    field :other_language, :string
    field :nickname, :string
    field :member_psw, :string
    field :phone_number, :string
    field :viber_number, :string
    field :messenger_number, :string
    field :role, :string, default: "MEMBER"
    field :token, :string
    field :token_expiration, :utc_datetime
    field :embassador, :boolean, default: false
    field :first_offer_date, :utc_datetime
    has_many :announces, Announce, on_delete: :delete_all
    has_one :conversation, Conversation, on_delete: :delete_all
    has_many :phones, Phone, on_delete: :delete_all
    has_many :treated_offers, Announce, foreign_key: :treated_by_id, on_delete: :nilify_all
    timestamps()
  end

  @required_fields ~w(uid language nickname phone_number role active)a
  @optional_fields ~w(auth_provider email member_psw viber_number other_language embassador first_offer_date)a

  @doc false
  def changeset(user, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni(["nickname"])
    user
      |> Map.put(:uid, Ecto.UUID.generate)
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_format(:email, email_regex(), message: "This is not a real email")
      |> validate_format(:phone_number, myanmar_phone_regex(), message: "This is not a Myanmar phone number")
      |> validate_format(:viber_number, myanmar_phone_regex(), message: "This is not a Myanmar Viber phone number")
      # |> convert_viber_number(attrs)
      |> validate_inclusion(:auth_provider, ["google"], message: "Oauth provider not supported")
      |> validate_length(:nickname, min: 3, max: 30, message: "Nickname length is not good")
      |> validate_inclusion(:language, ["dz", "my", "en"], message: "Language not supported")
      |> validate_inclusion(:other_language, ["my", "en", "cn", "jp", "kr"], message: "Language not supported")
      |> validate_inclusion(:role, ["GUEST", "MEMBER", "ADMIN", "PARTNER", "SUPER"], message: "Role not supported")
      |> refuse_guest_phone_number(params)
  end

  defp refuse_guest_phone_number(changeset, %{"phone_number" => "09000000000"}) do
      add_error(changeset, :phone_number, "Guest phone number can't post offer")
  end
  defp refuse_guest_phone_number(changeset, _params) do
      changeset
  end

  # defp convert_viber_number(changeset, %{"viber_number" => viber_number}) do
  #   case viber_number do
  #     "" -> changeset
  #     _ -> put_change(changeset, :viber_number, "+959#{String.slice(viber_number, 2..10)}")
  #   end
  # end
  # defp convert_viber_number(changeset, _) do
  #   changeset
  # end

  def show_errors_in_msg(changeset) do
    case List.first(changeset.errors) do
      {:nickname, _msg} -> dgettext("errors", "Please check your nickname.")
      {:phone_number, {"Guest phone number can't post offer", _}} -> dgettext("errors", "Please check your phone number.")
      {:phone_number, _msg} -> dgettext("errors", "Phone number is already taken.")
      {:viber_number, _msg} -> dgettext("errors", "Viber phone number is not correct (+95....)")
      {:email, {"Email is already taken", _}} -> dgettext("errors", "This email is already used by another user.")
      {:email, {"This is not a real email", _}} -> dgettext("errors", "This email not a proper email.")
      _ -> # Something else went wrong
        dgettext("errors", "Sorry we have a technical problem..")
    end
  end

  def check_myanmar_phone_number(phone_number) do
    String.match?(phone_number, myanmar_phone_regex())
  end

  def email_regex() do
    # ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
    ~r/^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  end
  def myanmar_phone_regex() do
    # ~r/^[0][9]\d{9}$/ # 09 + 9 digits
    ~r/^([0][9])(\d{7}|\d{8}|\d{9})$/ # 09 + 7 to 9 digits
  end
  # def viber_regex() do
  #   ~r/^\+[1-9]{1,2}\d{5,10}$/
  # end

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

  def filter_not_guest(query) do
    from u in query,
      where: u.role != "GUEST"
  end

  def filter_super_users(query) do
    from u in query,
      where: u.role in ["SUPER"]
  end

  def filter_active_user_by_bot_id(query, bot_id, provider) do
    from u in query,
      join: c in assoc(u, :conversation),
      where: c.psid == ^bot_id and c.bot_provider == ^provider and u.active == true
  end

  def filter_active_user_by_phone_number(query, phone_number) do
    from u in query,
      where: u.phone_number == ^phone_number and u.active == true
  end

  def filter_user_public_data(query) do
    from u in query,
      select: %{nickname: u.nickname, phone_number: u.phone_number, viber_number: u.viber_number, language: u.language, other_language: u.other_language}
  end

  def filter_embassador_users(query, user_id) do
    from u in query,
      join: c in assoc(u, :conversation),
      where: c.origin == ^user_id and u.active == true
  end

  def filter_users_created_in_month(query, month, year) do
    from u in query,
      where: fragment("date_part('month', ?)", u.inserted_at) == ^String.to_integer(month) and fragment("date_part('year', ?)", u.inserted_at) == ^String.to_integer(year)
  end

  def filter_users_with_one_published_offer(query) do
    from u in query,
      where: not is_nil(u.first_offer_date)
  end

  def filter_users_with_one_published_offer_in_month(query, month, year) do
    from u in query,
      where: fragment("date_part('month', ?)", u.first_offer_date) == ^String.to_integer(month) and fragment("date_part('year', ?)", u.first_offer_date) == ^String.to_integer(year)
  end

  def count(query) do
    from u in query,
      select: count("*")
  end

end
