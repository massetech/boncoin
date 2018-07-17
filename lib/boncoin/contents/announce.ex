defmodule Boncoin.Contents.Announce do
  use Ecto.Schema
  import Ecto.Changeset
  alias Boncoin.Contents.{Category, Township, Image}
  alias Boncoin.Members.{User}

  schema "announces" do
    field :conditions, :boolean, default: false
    field :description, :string
    field :priority, :boolean, default: false
    field :language, :string
    field :latitute, :string
    field :longitude, :string
    field :price, :float
    field :currency, :string, default: "Kyats"
    field :status, :string, default: "PENDING"
    field :title, :string
    field :nb_view, :integer, default: 0
    field :nb_clic, :integer, default: 0
    field :nb_alert, :integer, default: 0
    field :validity_date, :utc_datetime
    field :parution_date, :utc_datetime
    belongs_to :user, User
    belongs_to :category, Category
    belongs_to :township, Township
    has_many :images, Image, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(user_id category_id township_id title price description currency)a
  @optional_fields ~w(status latitute longitude conditions nb_view nb_clic nb_alert validity_date parution_date priority)a

  @doc false
  def changeset(announce, attrs) do
    announce
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:category)
    |> assoc_constraint(:township)
    |> validate_inclusion(:status, ["PENDING", "ONLINE", "REFUSED", "OUTDATED"])
    |> validate_inclusion(:currency, ["Kyats", "Lacks", "USD"])
  end

  def status_select_btn() do
    [pending: "PENDING", accepted: "ONLINE", refused: "REFUSED", outdated: "OUTDATED"]
  end
end
