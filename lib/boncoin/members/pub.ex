defmodule Boncoin.Members.Pub do
  use Ecto.Schema
  import Ecto.Changeset


  schema "pubs" do
    field :end_date, :utc_datetime
    field :language, :string
    field :link, :string
    field :nb_click, :integer
    field :nb_view, :integer
    field :priority, :integer
    field :start_date, :utc_datetime
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(pub, attrs) do
    pub
    |> cast(attrs, [:title, :start_date, :end_date, :language, :nb_view, :nb_click, :link, :priority])
    |> validate_required([:title, :start_date, :end_date, :language, :nb_view, :nb_click, :link, :priority])
  end
end
