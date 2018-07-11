defmodule Boncoin.Contents.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Family}

  schema "categorys" do
    field :active, :boolean, default: false
    field :title_bi, :string
    field :title_en, :string
    belongs_to :family, Family

    timestamps()
  end

  @required_fields ~w(title_bi title_en family_id)a
  @optional_fields ~w(active)a

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:family)
  end
end
