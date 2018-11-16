defmodule Boncoin.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :psid, :string
      add :bot_provider, :string
      add :scope, :string
      add :nickname, :string
      add :language, :string
      timestamps()
    end
  end
end
