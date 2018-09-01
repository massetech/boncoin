defmodule Boncoin.Contents.Image do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  alias Boncoin.Contents.{Announce, Image}
  use Arc.Ecto.Schema

  schema "images" do
    field :file, Boncoin.AnnounceImage.Type
    field :uuid, :string
    belongs_to :announce, Announce
    timestamps()
  end

  @required_fields ~w(uuid announce_id)a
  @optional_fields ~w()a

  @doc false
  def changeset(image, attrs) do
    image
    |> Map.put(:uuid, Ecto.UUID.generate)
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> assoc_constraint(:announce)
    |> fix_image_file(attrs)
  end

  # See fix on https://github.com/stavro/arc_ecto/issues/23
  defp fix_image_file(changeset, attrs) do
    IO.inspect(attrs)
    cond do
      attrs == %{file: nil} -> # We are in a image delete
        new_params = attrs
      true -> # We are on an image input
        decoded_file = attrs.file
          |> Poison.decode!
        new_params = %{
          "announce_id" => attrs.announce_id,
          "file" => %{
            # content_type: decoded_file["output"]["type"],
            filename: decoded_file["output"]["name"],
            binary: Base.decode64!(clean_up_picture_binary (decoded_file["output"]["image"]))
          }
        }
    end
    cast_attachments(changeset, new_params, [:file])
  end

  # Normal input for file images
  # %{
  #   "announce_id" => "1",
  #   "file" => %Plug.Upload{
  #     content_type: "image/jpeg",
  #     filename: "velo.jpeg",
  #     path: "/var/folders/yx/9k805vr91396t97nswvbp9q80000gn/T//plug-1531/multipart-1531645100-999261523634027-1"
  #   }
  # }

  defp clean_up_picture_binary (image_output) do
    image_output
      |> String.replace(~r[^data:image/\w+;base64,], "")
  end
end
