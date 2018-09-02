defmodule Boncoin.Contents do
  import Ecto.Query, warn: false
  alias Boncoin.{Repo, Members}
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce, Image}
  alias Boncoin.Members.{User}
  alias BoncoinWeb.ViberController

  # -------------------------------- FAMILY ----------------------------------------

  @doc """
  Returns the list of familys.

  ## Examples

      iex> list_familys()
      [%Family{}, ...]

  """
  def list_familys do
    Family
      |> Family.order_familys_for_public()
      |> Repo.all()
  end

  def list_familys_for_select() do
    Family
      |> Family.select_familys_for_dropdown()
      |> Repo.all()
  end

  @doc """
  Returns the list of active families and their active categories.
  """

  # def get_family_of_category(category_id) do
  #   Family
  #     |> fil
  #     |> Repo.one()
  # end

  def list_familys_active() do
    query = Category
      |> Category.filter_categorys_active()
    Family
      |> Family.filter_familys_active()
      |> Repo.all()
      |> Repo.preload([categorys: query])
  end

  @doc """
  Gets a single family.

  Raises `Ecto.NoResultsError` if the Family does not exist.

  ## Examples

      iex> get_family!(123)
      %Family{}

      iex> get_family!(456)
      ** (Ecto.NoResultsError)

  """
  def get_family!(id), do: Repo.get!(Family, id)

  @doc """
  Creates a family.

  ## Examples

      iex> create_family(%{field: value})
      {:ok, %Family{}}

      iex> create_family(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_family(attrs \\ %{}) do
    %Family{}
      |> Family.changeset(attrs)
      |> Repo.insert()
  end

  @doc """
  Updates a family.

  ## Examples

      iex> update_family(family, %{field: new_value})
      {:ok, %Family{}}

      iex> update_family(family, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_family(%Family{} = family, attrs) do
    family
      |> Family.changeset(attrs)
      |> Repo.update()
  end

  @doc """
  Deletes a Family.

  ## Examples

      iex> delete_family(family)
      {:ok, %Family{}}

      iex> delete_family(family)
      {:error, %Ecto.Changeset{}}

  """
  def delete_family(%Family{} = family) do
    Repo.delete(family)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking family changes.

  ## Examples

      iex> change_family(family)
      %Ecto.Changeset{source: %Family{}}

  """
  def change_family(%Family{} = family) do
    Family.changeset(family, %{})
  end

  # -------------------------------- CATEGORY ----------------------------------------

  @doc """
  Returns the list of categorys.

  ## Examples

      iex> list_categorys()
      [%Category{}, ...]

  """
  def list_categorys do
    Category
      |> Category.order_categorys_for_public()
      |> Repo.all()
      |> Repo.preload([:family])
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
      |> Category.changeset(attrs)
      |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
      |> Category.changeset(attrs)
      |> Repo.update()
  end

  @doc """
  Deletes a Category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{source: %Category{}}

  """
  def change_category(%Category{} = category) do
    Category.changeset(category, %{})
  end

  # -------------------------------- TOWNSHIP ----------------------------------------

  @doc """
  Returns the list of townships.

  ## Examples

      iex> list_townships()
      [%Township{}, ...]

  """
  def list_townships do
    Township
      |> Repo.all()
      |> Repo.preload([:division])
  end

  @doc """
  Gets a single township.

  Raises `Ecto.NoResultsError` if the Township does not exist.

  ## Examples

      iex> get_township!(123)
      %Township{}

      iex> get_township!(456)
      ** (Ecto.NoResultsError)

  """
  def get_township!(id) do
    Repo.get!(Township, id)
  end

  @doc """
  Creates a township.

  ## Examples

      iex> create_township(%{field: value})
      {:ok, %Township{}}

      iex> create_township(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_township(attrs \\ %{}) do
    %Township{}
      |> Township.changeset(attrs)
      |> Repo.insert()
  end

  @doc """
  Updates a township.

  ## Examples

      iex> update_township(township, %{field: new_value})
      {:ok, %Township{}}

      iex> update_township(township, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_township(%Township{} = township, attrs) do
    township
      |> Township.changeset(attrs)
      |> Repo.update()
  end

  @doc """
  Deletes a Township.

  ## Examples

      iex> delete_township(township)
      {:ok, %Township{}}

      iex> delete_township(township)
      {:error, %Ecto.Changeset{}}

  """
  def delete_township(%Township{} = township) do
    Repo.delete(township)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking township changes.

  ## Examples

      iex> change_township(township)
      %Ecto.Changeset{source: %Township{}}

  """
  def change_township(%Township{} = township) do
    Township.changeset(township, %{})
  end

  # -------------------------------- DIVISION ----------------------------------------

  @doc """
  Returns the list of divisions.

  ## Examples

      iex> list_divisions()
      [%Division{}, ...]

  """
  def list_divisions do
    Division
      |> Repo.all()
  end

  def list_divisions_for_select() do
    Division
      |> Division.select_divisions_for_dropdown()
      |> Repo.all()
  end

  @doc """
  Returns the list of active divisions and their active townships.
  """

  def list_divisions_active do
    query = Township
      |> Township.filter_townships_active()
    Division
      |> Division.filter_divisions_active()
      |> Repo.all()
      |> Repo.preload([townships: query])
  end

  @doc """
  Gets a single division.

  Raises `Ecto.NoResultsError` if the Division does not exist.

  ## Examples

      iex> get_division!(123)
      %Division{}

      iex> get_division!(456)
      ** (Ecto.NoResultsError)

  """
  def get_division!(id), do: Repo.get!(Division, id)

  @doc """
  Creates a division.

  ## Examples

      iex> create_division(%{field: value})
      {:ok, %Division{}}

      iex> create_division(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_division(attrs \\ %{}) do
    %Division{}
      |> Division.changeset(attrs)
      |> Repo.insert()
  end

  @doc """
  Updates a division.

  ## Examples

      iex> update_division(division, %{field: new_value})
      {:ok, %Division{}}

      iex> update_division(division, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_division(%Division{} = division, attrs) do
    division
      |> Division.changeset(attrs)
      |> Repo.update()
  end

  @doc """
  Deletes a Division.

  ## Examples

      iex> delete_division(division)
      {:ok, %Division{}}

      iex> delete_division(division)
      {:error, %Ecto.Changeset{}}

  """
  def delete_division(%Division{} = division) do
    Repo.delete(division)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking division changes.

  ## Examples

      iex> change_division(division)
      %Ecto.Changeset{source: %Division{}}

  """
  def change_division(%Division{} = division) do
    Division.changeset(division, %{})
  end

  # -------------------------------- ANNOUNCE ----------------------------------------

  def list_announces do
    Announce
      |> Announce.list_admin_announces()
      |> Repo.all()
      |> Repo.preload([:user, :category, township: [:division]])
  end

  def list_announces_public(cursor_after, %{"category_id" => category_id, "division_id" => division_id, "family_id" => family_id, "township_id" => township_id} = params) do
    user_query = User
      |> User.filter_user_public_data()
    offer_query = Announce
      |> Announce.filter_announces_online()
      |> Announce.filter_announces_by_location(division_id, township_id)
      |> Announce.filter_announces_by_kind(family_id, category_id)
      |> Announce.sort_announces_for_pagination()
      |> Announce.select_announces_datas(user_query)
    # Process.sleep(3000)
    case cursor_after do
      nil -> # Call the first time
        %{entries: entries, metadata: metadata} = Repo.paginate(offer_query, include_total_count: true, cursor_fields: [:priority, :parution_date], sort_direction: :desc, limit: 4)
      _ -> # load more entries
        %{entries: entries, metadata: metadata} = Repo.paginate(offer_query, after: cursor_after, include_total_count: true, cursor_fields: [:priority, :parution_date], sort_direction: :desc, limit: 4)
    end
  end

  def count_announces_public() do
    Announce
      |> Announce.count_announces_online()
      |> Repo.one()
  end

  def get_user_offers(user) do
    Announce
      |> Announce.select_user_offers(user)
      |> Repo.all()
  end

  def get_announce!(id) do
    Repo.get!(Announce, id)
      |> Repo.preload([:user, :images, township: [:division], category: [:family]])
  end

  def create_announce(attrs \\ %{}) do
    params = attrs
      |> Map.merge(%{"status" => "PENDING"})
      # Convert Zawgyi to Unicode before inserting into database
      |> Map.merge(%{"title" => Rabbit.zg2uni(attrs["title"]), "description" => Rabbit.zg2uni(attrs["description"])})
      # |> IO.inspect(limit: :infinity, printable_limit: :infinity)
    offer = %Announce{}
      |> Announce.changeset(params)
      |> Announce.check_offer_has_one_photo_min(params)
      |> Repo.insert()
      # |> IO.inspect()
    case offer do
      {:ok, announce} ->
        # Loop on the 3 photo fields of the form params
        for i <- ["image_file_1", "image_file_2", "image_file_3"] do
          unless attrs[i] == "" do
            create_announce_image(announce.id, attrs[i])
          end
        end
        # Encrypt announce ID and generate a safe_link
        update_announce(announce, %{"safe_link" => build_safe_link(announce.id)})
      error -> error
    end
  end

  defp build_safe_link(announce_id) do
    Cipher.encrypt(Kernel.inspect(announce_id))
  end

  def validate_announce(admin_user, %{"announce_id" => announce_id, "validate" => validate, "cause" => cause, "category_id" => category_id}) do
    announce = get_announce!(announce_id)
    user = Members.get_user!(announce.user_id)
    status = case validate do
      "true" -> "ONLINE"
      "false" -> "REFUSED"
    end
    if category_id == nil, do: category_id = announce.category_id, else: category_id
    dates = calc_announce_validity_date()
    # Build the params
    params = %{treated_by_id: admin_user.id, status: status, cause: cause, category_id: category_id, parution_date: dates.parution_date, validity_date: dates.validity_date}
    # Update the announce
    case update_announce(announce, params) do
      {:ok, announce} ->
        # Call Viber bot
        if user.viber_active == true do
          bot_datas = %{tracking_data: "offer_treated", details: %{user: user, language: user.language, viber_id: user.viber_id, viber_name: user.nickname, user_msg: ""}, announce: announce}
            |> ViberController.call_bot_algorythm()
            |> Enum.map(fn result_map -> ViberController.send_viber_message(user.viber_id, result_map.tracking_data, result_map.msg) end)
        end
        {:ok, announce}
      {:error, msg} -> {:error, msg}
    end
  end

  defp calc_announce_validity_date() do
    parution_date = Timex.now()
    validity_date = Timex.shift(parution_date, days: 30)
    %{parution_date: parution_date, validity_date: validity_date}
  end

  def update_announce(%Announce{} = announce, attrs) do
    announce
    |> Announce.changeset(attrs)
    |> Repo.update()
  end

  def delete_announce(%Announce{} = announce) do
    # Remove the link to the images first to delete from socket
    # see https://github.com/stavro/arc_ecto/issues/40
    images = announce.images
    for image <- images do
      image
        |> Image.changeset(%{file: nil})
        |> Repo.update!()
      # Delete asynchronously to speed up the request/response.
      spawn(fn -> Boncoin.AnnounceImage.delete({image.file, image}) end)
    end
    # Delete the announce will delete the images (belongs_to)
    Repo.delete(announce)
  end

  def change_announce(%Announce{} = announce) do
    Announce.changeset(announce, %{})
  end

  # -------------------------------- IMAGE ----------------------------------------

  @doc """
  Returns the list of images.

  ## Examples

      iex> list_images()
      [%Image{}, ...]

  """
  def list_images do
    Repo.all(Image)
  end

  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get!(Image, id)

  @doc """
  Creates a image.
  Can receive binary datas from the form :
      announce_id: announce.id,
      file: %{
        content_type: img_params["output"]["type"],
        filename: img_params["output"]["name"],
        binary: Base.decode64!(clean_up_picture_file (img_params))
      }

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_announce_image(announce_id, file) do
    image_params = %{announce_id: announce_id, file: file}
    %Image{}
      |> Image.changeset(image_params)
      |> Repo.insert()
  end

  def create_image(attrs \\ %{}) do
    %Image{}
      |> Image.changeset(attrs)
      |> Repo.insert()
  end

  @doc """
  Updates a image.

  ## Examples

      iex> update_image(image, %{field: new_value})
      {:ok, %Image{}}

      iex> update_image(image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  # def update_image(%Image{} = image, attrs) do
  #   image
  #   |> Image.changeset(attrs)
  #   |> Repo.update()
  # end

  @doc """
  Deletes a Image.

  ## Examples

      iex> delete_image(image)
      {:ok, %Image{}}

      iex> delete_image(image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking image changes.

  ## Examples

      iex> change_image(image)
      %Ecto.Changeset{source: %Image{}}

  """
  def change_image(%Image{} = image) do
    Image.changeset(image, %{})
  end
end
