defmodule Boncoin.Contents.Family do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Category}

  schema "familys" do
    field :active, :boolean
    field :title_my, :string
    field :title_en, :string
    field :rank, :integer
    field :icon, :string, default: "home"
    field :icon_type, :string, default: "fa"
    has_many :categorys, Category, on_delete: :delete_all
    # has_many :announces, through: [:categorys, :announces]
    timestamps()
  end

  @required_fields ~w(title_my title_en icon icon_type active rank)a
  @optional_fields ~w()a

  @doc false
  def changeset(family, attrs) do
    family
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
