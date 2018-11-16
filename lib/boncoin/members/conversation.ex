defmodule Boncoin.Members.Conversation do
  use Ecto.Schema
  import Ecto.{Query, Changeset}

  schema "conversations" do
    field :bot_provider, :string
    field :psid, :string
    field :scope, :string, default: "language"
    field :nickname, :string
    field :language, :string, default: "dz"
    timestamps()
  end

  @required_fields ~w(psid bot_provider scope)a
  @optional_fields ~w(nickname language)a

  @doc false
  def changeset(conversation, params) do
    conversation
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      # |> validate_inclusion(:scope, ["language"], message: "Scope not supported")
      |> validate_inclusion(:language, ["dz", "my", "en"], message: "Language not supported")
      |> validate_inclusion(:bot_provider, ["viber", "messenger"], message: "Bot provider not supported")
  end

  def filter_conversation_by_bot(query, bot_provider, psid) do
    from c in query,
      where: c.bot_provider == ^bot_provider and c.psid == ^psid
  end
end
