defmodule Boncoin.Contents.TrafficKpi do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.Contents.{Township}

  schema "traffickpis" do
    field :nb_new_guest, :integer, default: 0
    field :nb_old_guest, :integer, default: 0
    field :nb_clic_offers, :integer, default: 0
    field :nb_cat_searches, :integer, default: 0
    field :nb_click_add_more, :integer, default: 0
    field :date, :utc_datetime
    belongs_to :township, Township
    timestamps()
  end

  @required_fields ~w(township_id date)a
  @optional_fields ~w(nb_new_guest nb_old_guest nb_cat_searches nb_click_add_more nb_clic_offers)a

  @doc false
  def changeset(traffic_kpi, attrs) do
    traffic_kpi
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> assoc_constraint(:township)
  end

  def select_township_traffic_kpi_by_date(query, township_id, date) do
    from k in query,
      where: k.township_id == ^township_id #and k.date.year == ^date.year and k.date.month == ^date.month and k.date.day == ^date.day
      and fragment("?::date", k.date) == ^date
  end

end
