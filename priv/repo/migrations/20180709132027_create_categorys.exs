defmodule Boncoin.Repo.Migrations.CreateCategorys do
  use Ecto.Migration

  def change do
    create table(:categorys) do
      add :title_en, :string
      add :title_bi, :string
      add :active, :boolean, default: false, null: false
      add :family_id, references(:familys, on_delete: :nothing)
      timestamps()
    end
    create index(:categorys, [:family_id])
  end
end
