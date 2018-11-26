defmodule Boncoin.Repo.Migrations.ChangePrice do
  use Ecto.Migration

  def change do
    alter table(:announces) do
      modify :price, :string
    end
  end
end
