defmodule Boncoin.Repo.Migrations.AddSpeakingLanguages do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :other_language, :string
    end
  end
end
