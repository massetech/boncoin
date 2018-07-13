defmodule Boncoin.Contents.Township do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Division, Announce}

  schema "townships" do
    field :active, :boolean, default: false
    field :latitute, :string
    field :longitude, :string
    field :title_bi, :string
    field :title_en, :string
    belongs_to :division, Division
    has_many :announces, Announce, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(title_en title_bi division_id)a
  @optional_fields ~w(active latitute longitude)a

  @doc false
  def changeset(township, attrs) do
    township
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:division)
  end
end
