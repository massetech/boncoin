defmodule Boncoin.Contents.Family do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Category}

  schema "familys" do
    field :active, :boolean, default: false
    field :title_bi, :string
    field :title_en, :string
    field :icon, :string
    has_many :categorys, Category, on_delete: :delete_all
    has_many :announces, through: [:categorys, :announces]
    timestamps()
  end

  @required_fields ~w(title_bi title_en icon)a
  @optional_fields ~w(active)a

  @doc false
  def changeset(family, attrs) do
    family
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
