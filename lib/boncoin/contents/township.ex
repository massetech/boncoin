defmodule Boncoin.Contents.Township do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.Contents.{Division, Announce, TrafficKpi}

  schema "townships" do
    field :active, :boolean
    field :latitute, :string
    field :longitude, :string
    field :title_my, :string
    field :title_en, :string
    belongs_to :division, Division
    has_many :announces, Announce, on_delete: :delete_all
    has_many :traffic_kpis, TrafficKpi, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(title_en title_my division_id)a
  @optional_fields ~w(active latitute longitude)a

  @doc false
  def changeset(township, attrs) do
    township
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> assoc_constraint(:division)
  end

  def filter_townships_active(query) do
    from t in query,
      where: t.active == true,
      select: [:id, :title_en, :title_my]
  end

end
