defmodule Boncoin.Repo.Migrations.AddEmbassadors do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :embassador, :boolean, default: false
      add :first_offer_date, :utc_datetime
    end
  end
end
