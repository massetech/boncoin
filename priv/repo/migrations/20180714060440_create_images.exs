defmodule Boncoin.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :uuid, :string
      add :file, :string
      add :announce_id, references(:announces, on_delete: :delete_all)
      timestamps()
    end
  end
end
