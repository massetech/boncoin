defmodule Boncoin.Repo.Migrations.CreatePhones do
  use Ecto.Migration

  def change do
    create table(:phones) do
      add :phone_number, :string
      add :active, :boolean, default: false, null: false
      add :creation_date, :utc_datetime
      add :closing_date, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)
      timestamps()
    end

  end
end
