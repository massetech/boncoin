defmodule Boncoin.Contents.Family do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
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

  def filter_familys_active(query) do
    from f in query,
      where: f.active == true,
      order_by: [asc: :rank, asc: :id],
      select: [:id, :title_en, :title_my, :icon]
  end

  def select_familys_for_dropdown(query) do
    from f in query,
      select: {f.title_en, f.id},
      order_by: [asc: :rank]
  end

  def order_familys_for_public(query) do
    from f in query,
      order_by: [asc: :rank, asc: :title_en]
  end

end
