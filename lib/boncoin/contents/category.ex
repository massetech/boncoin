defmodule Boncoin.Contents.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Family, Announce}

  schema "categorys" do
    field :active, :boolean
    field :title_my, :string
    field :title_en, :string
    field :rank, :integer
    field :icon, :string, default: "home"
    field :icon_type, :string, default: "fa"
    belongs_to :family, Family
    has_many :announces, Announce, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(title_my title_en family_id icon icon_type active rank)a
  @optional_fields ~w()a

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:family)
  end
end
