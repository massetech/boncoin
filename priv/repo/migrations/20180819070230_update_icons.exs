defmodule Boncoin.Repo.Migrations.UpdateIcons do
  use Ecto.Migration

  def change do
    alter table(:categorys) do
      add :icon_type, :text
      add :rank, :integer
    end
    alter table(:familys) do
      add :icon_type, :text
      add :rank, :integer
    end
  end
end
