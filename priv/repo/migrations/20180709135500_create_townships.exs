defmodule Boncoin.Repo.Migrations.CreateTownships do
  use Ecto.Migration

  def change do
    create table(:townships) do
      add :title_en, :string
      add :title_my, :string
      add :active, :boolean, default: false, null: false
      add :latitute, :string
      add :longitude, :string
      add :division_id, references(:divisions, on_delete: :nothing)
      timestamps()
    end
    create index(:townships, [:division_id])
  end
end
