defmodule Boncoin.Repo.Migrations.UpdateUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :bot_active
      remove :bot_id
      remove :bot_provider
    end
    alter table(:conversations) do
      add :active, :boolean, default: true, null: false
      add :origin, :string
      add :user_id, references(:users, on_delete: :delete_all)
      add :nb_errors, :integer
    end
    alter table(:phones) do
      add :bot_id, :string
      add :bot_provider, :string
      add :nickname, :string
    end
  end
end
