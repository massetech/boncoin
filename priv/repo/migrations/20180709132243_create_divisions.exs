defmodule Boncoin.Repo.Migrations.CreateDivisions do
  use Ecto.Migration

  def change do
    create table(:divisions) do
      add :title_en, :string
      add :title_my, :string
      add :active, :boolean, default: false, null: false
      add :latitute, :string
      add :longitude, :string
      timestamps()
    end
  end
end
