defmodule Boncoin.Repo.Migrations.CreatePubs do
  use Ecto.Migration

  def change do
    create table(:pubs) do
      add :title, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :language, :string
      add :nb_view, :integer
      add :nb_click, :integer
      add :link, :string
      add :priority, :integer

      timestamps()
    end

  end
end
