defmodule Boncoin.Repo.Migrations.ModifyBotStructure do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :bot_provider, :string
      add :viber_number, :string
      add :messenger_number, :string
      add :active, :boolean, default: true, null: false
    end
    alter table(:announces) do
      add :sell_mode, :string
    end
    rename table(:users), :viber_active, to: :bot_active
    rename table(:users), :viber_id, to: :bot_id
    rename table(:users), :provider, to: :auth_provider
  end
end
