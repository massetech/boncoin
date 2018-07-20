defmodule Boncoin.Repo.Migrations.CreateAnnounces do
  use Ecto.Migration

  def change do
    create table(:announces) do
      add :title, :string
      add :conditions, :boolean, default: false, null: false
      add :priority, :boolean, default: false, null: false
      add :latitute, :string
      add :longitude, :string
      add :status, :string
      add :validity_date, :utc_datetime
      add :parution_date, :utc_datetime
      add :price, :float
      add :currency, :string
      add :description, :text
      add :language, :string
      add :nb_view, :integer
      add :nb_clic, :integer
      add :nb_alert, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :township_id, references(:townships, on_delete: :nothing)
      add :category_id, references(:categorys, on_delete: :nothing)
      add :zawgyi, :boolean, default: false, null: false
      timestamps()
    end
    create index(:announces, [:user_id])
    create index(:announces, [:township_id])
    create index(:announces, [:category_id])
  end
end
