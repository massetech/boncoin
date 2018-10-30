defmodule Boncoin.Members.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :bot_provider, :string
    field :psid, :string
    field :scope, :string, default: "language"
    field :nickname, :string
    timestamps()
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:psid, :bot_provider, :scope, :nickname])
    |> validate_required([:psid, :bot_provider, :scope])
    |> validate_inclusion(:bot_provider, ["viber", "messenger"])
  end
end
