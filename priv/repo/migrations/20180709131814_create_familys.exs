defmodule Boncoin.Repo.Migrations.CreateFamilys do
  use Ecto.Migration

  def change do
    create table(:familys) do
      add :title_en, :string
      add :title_my, :string
      add :icon, :string
      add :active, :boolean, default: false, null: false
      timestamps()
    end
  end
end
