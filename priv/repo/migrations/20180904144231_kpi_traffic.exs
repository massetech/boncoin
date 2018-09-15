defmodule Boncoin.Repo.Migrations.TrafficKpi do
  use Ecto.Migration

  def change do
    create table(:traffickpis) do
      add :township_id, references(:townships, on_delete: :delete_all)
      add :nb_new_guest, :integer, default: 0
      add :nb_old_guest, :integer, default: 0
      add :nb_clic_offers, :integer, default: 0
      add :nb_cat_searches, :integer, default: 0
      add :nb_click_add_more, :integer, default: 0
      add :date, :utc_datetime
      timestamps()
    end
  end
end
