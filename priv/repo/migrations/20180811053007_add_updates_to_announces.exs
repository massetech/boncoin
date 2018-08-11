defmodule Boncoin.Repo.Migrations.AddUpdatesToAnnounces do
  use Ecto.Migration

  def change do
    alter table(:announces) do
      add :safe_link, :string
      add :closing_date, :utc_datetime
    end
  end
end
