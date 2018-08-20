defmodule Boncoin.Members.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Announce}
  alias Boncoin.CustomModules

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

  @required_fields ~w()a
  @optional_fields ~w(uid role nickname phone_number email viber_active viber_id language member_psw)a

  @doc false
  def changeset(user, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni([:email, :nickname])
    user
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email, message: "Email is already taken")
    |> unique_constraint(:phone_number, message: "Phone number is already taken")
    # |> validate_format(:email, ~r/@/, message: "This is not an email")
    # |> validate_format(:phone_number, ~r/@/, message: "This is not a Myanmar phone number")
    |> validate_inclusion(:provider, ["google"])
    |> validate_inclusion(:role, ["GUEST", "MEMBER", "ADMIN", "SUPER"])
  end

  def role_select_btn() do
    [guest: "GUEST", member: "MEMBER", admin: "ADMIN", super: "SUPER"]
  end
end
