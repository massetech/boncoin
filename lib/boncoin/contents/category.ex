defmodule Boncoin.Contents.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Family, Announce}

  schema "categorys" do
    field :active, :boolean, default: false
    field :title_my, :string
    field :title_en, :string
    field :icon, :string, default: "whmcs"
    belongs_to :family, Family
    has_many :announces, Announce, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(title_my title_en family_id icon)a
  @optional_fields ~w(active)a

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:family)
  end
end
