defmodule Boncoin.Members.Conversation do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.CustomModules

  # Select only those fields to encode in json the API response
  @derive {Jason.Encoder, only: [:bot_provider, :active]}

  schema "conversations" do
    field :psid, :string
    field :bot_provider, :string, default: "messenger"
    field :scope, :string, default: "language"
    field :nickname, :string
    field :language, :string, default: "dz"
    field :origin, :string
    field :active, :boolean, default: true
    field :nb_errors, :integer, default: 0
    belongs_to :user, User
    timestamps()
  end

  @required_fields ~w(psid bot_provider scope nickname active)a
  @optional_fields ~w(language origin user_id nb_errors)a

  @doc false
  def changeset(conversation, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni(["nickname"])
    conversation
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> validate_length(:nickname, min: 3, max: 30, message: "Nickname length is not good")
      |> validate_inclusion(:language, ["dz", "my", "en"], message: "Language not supported")
      |> validate_inclusion(:bot_provider, ["viber", "messenger"], message: "Bot provider not supported")
  end

  def filter_conversation_by_bot(query, bot_provider, psid) do
    from c in query,
      where: c.bot_provider == ^bot_provider and c.psid == ^psid
  end
end
