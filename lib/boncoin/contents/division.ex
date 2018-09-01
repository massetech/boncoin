defmodule Boncoin.Contents.Division do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.Contents.{Township}

  schema "divisions" do
    field :active, :boolean
    field :latitute, :string
    field :longitude, :string
    field :title_my, :string
    field :title_en, :string
    has_many :townships, Township, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(title_en title_my)a
  @optional_fields ~w(active latitute longitude)a

  @doc false
  def changeset(division, attrs) do
    division
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def filter_divisions_active(query) do
    from d in query,
      where: d.active == true,
      select: [:id, :title_en, :title_my]
  end

  def select_divisions_for_dropdown(query) do
    from f in query,
      select: {f.title_en, f.id}
  end

end
