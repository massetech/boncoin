defmodule Boncoin.Contents do
  import Ecto.Query, warn: false
  alias Boncoin.{Repo, Members}
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce, Image}
  alias BoncoinWeb.ViberController

  # -------------------------------- FAMILY ----------------------------------------
  # QUERIES ------------------------------------------------------------------
  defp filter_familys_active(query \\ Family) do
    from f in query,
      where: f.active == true,
      order_by: [asc: :rank, asc: :id],
      select: [:id, :title_en, :title_my, :icon]
  end

  defp select_familys_for_dropdown(query \\ Family) do
    from f in query,
      select: {f.title_en, f.id},
      order_by: [asc: :rank]
  end

  defp order_familys(query \\ Family) do
    from f in query,
      order_by: [asc: :rank, asc: :title_en]
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Returns the list of familys.

  ## Examples

      iex> list_familys()
      [%Family{}, ...]

  """
  def list_familys do
    Family
      |> order_familys()
      |> Repo.all()
  end

  def list_familys_for_select() do
    select_familys_for_dropdown
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

  def list_familys_active do
    query = filter_categorys_active()
    Family
      |> filter_familys_active()
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
  # QUERIES ------------------------------------------------------------------
  defp filter_categorys_active(query \\ Category) do
    from c in query,
      where: c.active == true,
      order_by: [asc: :rank, asc: :id],
      select: [:id, :title_en, :title_my, :icon]
  end

  defp order_categorys(query \\ Category) do
    from f in query,
      order_by: [asc: :family_id, asc: :rank, asc: :title_en]
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Returns the list of categorys.

  ## Examples

      iex> list_categorys()
      [%Category{}, ...]

  """
  def list_categorys do
    Category
      |> order_categorys()
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
  # QUERIES ------------------------------------------------------------------
  defp filter_townships_active(query \\ Township) do
    from t in query,
      where: t.active == true,
      select: [:id, :title_en, :title_my]
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Returns the list of townships.

  ## Examples

      iex> list_townships()
      [%Township{}, ...]

  """
  def list_townships do
    Repo.all(Township)
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
  # QUERIES ------------------------------------------------------------------
  defp filter_divisions_active(query \\ Division) do
    from d in query,
      where: d.active == true,
      select: [:id, :title_en, :title_my]
  end

  defp select_divisions_for_dropdown(query \\ Division) do
    from f in query,
      select: {f.title_en, f.id}
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Returns the list of divisions.

  ## Examples

      iex> list_divisions()
      [%Division{}, ...]

  """
  def list_divisions do
    Repo.all(Division)
  end

  def list_divisions_for_select() do
    select_divisions_for_dropdown
      |> Repo.all()
      # |> IO.inspect()
  end

  @doc """
  Returns the list of active divisions and their active townships.
  """

  def list_divisions_active do
    query = filter_townships_active()
    Division
      |> filter_divisions_active()
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
  # QUERIES ------------------------------------------------------------------
  defp filter_announces_online(query \\ Announce) do
    from a in query,
      where: a.status == "ONLINE"
  end

  defp list_admin_announces(query \\ Announce) do
    from a in query,
      order_by: [asc: :inserted_at, desc: :parution_date, desc: :nb_clic]
  end

  defp count_announces_online(query \\ Announce) do
    from a in query,
      where: a.status == "ONLINE",
      select: count("*")
  end

  defp select_announces_datas(query \\ Announce, user_query) do
    from a in query,
      preload: [:images, user: ^user_query, township: [:division]]
  end

  # defp filter_announce_public_data(query \\ Announce) do
  #   from a in query, abs(number)
  #     select: [:id, :price]
  #     # select: map(a, [:id, :price])
  #     # select: struct(a, [:id, :price])
  #     # select: %Announce{id: a.id, price: a.price}
  # end

  defp filter_announces_by_location(query \\ Announce, division_id, township_id) do
    case division_id do
      "" ->
        from a in query,
          join: t in assoc(a, :township), where: t.active == true,
          join: d in assoc(t, :division), where: d.active == true
      _ ->
        case township_id do
          "" ->
            from a in query,
              join: t in assoc(a, :township), where: t.active == true,
              join: d in assoc(t, :division), where: d.active == true and d.id == ^division_id
          _ ->
            from a in query,
              join: t in assoc(a, :township), where: t.active == true and t.id == ^township_id,
              join: d in assoc(t, :division), where: d.active == true and t.id == ^division_id
        end
    end
  end

  defp filter_announces_by_kind(query \\ Announce, family_id, category_id) do
    case family_id do
      "" ->
        from a in query,
          join: t in assoc(a, :category), where: t.active == true,
          join: d in assoc(t, :family), where: d.active == true
      _ ->
        case category_id do
          "" ->
            from a in query,
              join: t in assoc(a, :category), where: t.active == true,
              join: d in assoc(t, :family), where: d.active == true and d.id == ^family_id
          _ ->
            from a in query,
              join: t in assoc(a, :category), where: t.active == true and t.id == ^category_id,
              join: d in assoc(t, :family), where: d.active == true and t.id == ^family_id
        end
    end
  end

  defp select_user_offers(query \\ Announce, user) do
    from a in query,
      where: a.status == "ONLINE" and a.user_id == ^user.id
  end

  defp order_announces_for_pagination(query \\ Announce) do
    from a in query,
      order_by: [asc: a.priority, desc: a.parution_date, asc: a.id]
  end

  # METHODS ------------------------------------------------------------------

  def list_announces do
    Announce
    |> list_admin_announces()
    |> Repo.all()
    |> Repo.preload([:user, :category, township: [:division]])
  end

  def list_announces_public(cursor_after, %{"category_id" => category_id, "division_id" => division_id, "family_id" => family_id, "township_id" => township_id} = params) do
    # IO.inspect(params)
    user_query = Members.filter_user_public_data()
    query = Announce
      |> filter_announces_online()
      |> filter_announces_by_location(division_id, township_id)
      |> filter_announces_by_kind(family_id, category_id)
      |> order_announces_for_pagination()
      |> select_announces_datas(user_query)
    case cursor_after do
      nil -> # Call the first time
        %{entries: entries, metadata: metadata} = Repo.paginate(query, include_total_count: true, cursor_fields: [:priority, :parution_date, :id], limit: 2)
          |> IO.inspect()
      _ -> # load more entries
        %{entries: entries, metadata: metadata} = Repo.paginate(query, after: cursor_after, cursor_fields: [:priority, :parution_date, :id], limit: 2)
          |> IO.inspect()
    end
  end

  def count_announces_public() do
    Announce
      |> count_announces_online()
      |> Repo.one()
  end

  def get_user_offers(user) do
    Announce
      |> select_user_offers(user)
      |> Repo.all()
  end

  def get_announce!(id) do
    Repo.get!(Announce, id)
    |> Repo.preload([:user, :images, township: [:division], category: [:family]])
  end

  def create_announce(attrs \\ %{}) do
    params = attrs
      |> Map.merge(%{"status" => "PENDING"})
      # Convert Zawgyi to Unicode for database
      |> Map.merge(%{"title" => Rabbit.zg2uni(attrs["title"]), "description" => Rabbit.zg2uni(attrs["description"])})
      # |> IO.inspect()
      # |> IO.inspect(limit: :infinity, printable_limit: :infinity)
    new_announce = %Announce{}
      |> Announce.changeset(params)
      |> Repo.insert()
    case new_announce do
      {:ok, announce} ->
        # Loop on the 3 photo fields of the form
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
        # Build bot params
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
    # Remove the link to the images ; see https://github.com/stavro/arc_ecto/issues/40
    images = announce.images
    for image <- images do
      image
        |> Image.changeset(%{file: nil})
        |> Repo.update!()
      # Since the above deletion doesn't really need to happen synchronously, you can delete it asynchronously to speed up the request/response.
      spawn(fn -> Boncoin.AnnounceImage.delete({image.file, image}) end)
    end
    # Delete the announce will delete the images (belongs_to)
    Repo.delete(announce)
  end

  def change_announce(%Announce{} = announce) do
    Announce.changeset(announce, %{})
  end

  # -------------------------------- IMAGE ----------------------------------------
  # QUERIES ------------------------------------------------------------------
  # def filter_image_public_data(query \\ Image) do
  #   from i in Image,
  #     select: %{file: i.file}
  # end

  # METHODS ------------------------------------------------------------------

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
