defmodule Boncoin.Members.Phone do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.Members.{User}

  schema "phones" do
    field :phone_number, :string
    field :active, :boolean, default: true
    field :creation_date, :utc_datetime
    field :closing_date, :utc_datetime
    field :bot_id, :string
    field :bot_provider, :string
    field :nickname, :string
    belongs_to :user, User
    timestamps()
  end

  @required_fields ~w(user_id phone_number active bot_id bot_provider nickname)a
  @optional_fields ~w(creation_date closing_date)a

  @doc false
  def changeset(phone, params) do
    phone
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
  end

  def search_active_phone_for_user(query, user_id) do
    from p in query,
      where: p.user_id == ^user_id and p.active == true
  end

  def search_active_phone_for_phone_number(query, phone_number) do
    from p in query,
      where: p.phone_number == ^phone_number and p.active == true
  end

  def search_phones_for_user(query, user_id) do
    from p in query,
      where: p.user_id == ^user_id
  end
end
