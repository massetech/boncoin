defmodule Boncoin.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :uid, :string
      add :role, :string
      add :nickname, :string
      add :phone_number, :string
      add :email, :string
      add :viber_active, :boolean, default: false, null: false
      add :viber_id, :string
      add :language, :string
      add :provider, :string
      add :token, :string
      add :token_expiration, :utc_datetime
      add :member_psw, :string
      timestamps()
    end

  end
end
