defmodule Boncoin.AnnounceImage do
  use Arc.Definition
  use Arc.Ecto.Definition

  # To add a thumbnail version:
  # @versions [:original, :thumb]
  @versions [:original]

  def __storage, do: Arc.Storage.GCS

  def gcs_object_headers(:original, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .jpeg .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  # end

  # Override the persisted filenames:
  # def filename(version, _) do
  #   version
  # end

  # Override the storage directory:
  # def storage_dir(version, {file, scope}) do
  #   "uploads/user/avatars/#{scope.id}"
  # end

  # https://elixirforum.com/t/how-can-i-use-unique-filename-generator-function-with-arc-ecto/4476/4
  def filename(version, {file, scope}) do
    # file_name = Path.basename(file.file_name, Path.extname(file.file_name))
    # "#{file_name}_#{version}_#{:os.system_time}"
    # https://elixirforum.com/t/how-can-i-use-unique-filename-generator-function-with-arc-ecto/4476/3
    "announce_#{scope.announce_id}_#{scope.uuid}_#{version}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(version, scope) do
    # "/images/announce_image/default_#{version}.png"
    "/images/announce_image/default_picture.png"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
