defmodule Boncoin.Contents.Announce do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Category, Township}

  schema "announces" do
    field :conditions, :boolean, default: false
    field :description, :string
    field :priority, :boolean, default: false
    field :language, :string
    field :latitute, :string
    field :longitude, :string
    field :photo1, :string
    field :photo2, :string
    field :photo3, :string
    field :price, :float
    field :status, :string
    field :title, :string
    field :nb_view, :integer
    field :nb_clic, :integer
    field :nb_alert, :integer
    field :validity_date, :utc_datetime
    field :parution_date, :utc_datetime
    belongs_to :category, Category
    belongs_to :township, Township
    timestamps()
  end

  @required_fields ~w(category_id township_id title price description)a
  @optional_fields ~w(latitute longitude photo1 photo2 photo3 conditions nb_view nb_clic nb_alert validity_date priority)a

  @doc false
  def changeset(announce, attrs) do
    announce
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:category)
    |> assoc_constraint(:township)
    |> validate_inclusion(:status, ["PENDING", "ACCEPTED", "REFUSED", "OUTDATED"])
  end

  def status_select_btn() do
    [pending: "PENDING", accepted: "ONLINE", refused: "REFUSED", outdated: "OUTDATED"]
  end
end
