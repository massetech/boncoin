defmodule Boncoin.Contents do
  import Ecto.Query, warn: false
  alias Boncoin.{Repo, Members}
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce}

  @doc """
  Returns the list of familys.

  ## Examples

      iex> list_familys()
      [%Family{}, ...]

  """
  def list_familys do
    Repo.all(Family)
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

  @doc """
  Returns the list of categorys.

  ## Examples

      iex> list_categorys()
      [%Category{}, ...]

  """
  def list_categorys do
    Repo.all(Category)
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
  def filter_townships_active(query \\ Township) do
    from t in query,
      where: t.active == true,
      select: struct(t, [:id, :title_en, :title_bi])
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
  def get_township!(id), do: Repo.get!(Township, id)

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
  def filter_divisions_active(query \\ Division) do
    from d in query,
      where: d.active == true,
      select: [:id, :title_en, :title_bi]
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

  @doc """
  Returns the list of active divisions and their active townships.

  ## Examples

      iex> list_townships()
      [%Township{}, ...]

  """

  def list_active_divisions do
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
      where: a.status == "ONLINE",
      order_by: [asc: :priority, desc: :parution_date, desc: :nb_clic]
  end

  defp filter_announces_by_location(query \\ Announce, division_id, township_id) do
    no_query = from a in query,
      join: t in assoc(a, :township), where: t.active == true,
      join: d in assoc(t, :division), where: d.active == true
    div_query = from a in query,
      join: t in assoc(a, :township), where: t.active == true,
      join: d in assoc(t, :division), where: d.active == true and d.id == ^division_id
    tws_query = from a in query,
      join: t in assoc(a, :township), where: t.active == true and t.id == ^township_id,
      join: d in assoc(t, :division), where: d.active == true and t.id == ^division_id
    case division_id do
      "" -> no_query
      _ ->
        case township_id do
          "" -> div_query
          _ -> tws_query
        end
    end
  end

  # METHODS ------------------------------------------------------------------

  @doc """
  Returns the list of announces.

  ## Examples

      iex> list_announces()
      [%Announce{}, ...]

  """
  def list_announces do
    Repo.all(Announce)
  end

  @doc """
  Returns the list of public announces for query.
  """

  def list_announces_public(%{"division" => division_id, "township" => township_id} =  search_params) do
    # division_id = search_params["division"] || nil
    # township_id = search_params["township"] || nil
    # IO.inspect(division_id)
    # IO.inspect(township_id)
    Announce
      |> filter_announces_online()
      |> filter_announces_by_location(division_id, township_id)
      |> Repo.all()
  end

  @doc """
  Gets a single announce.

  Raises `Ecto.NoResultsError` if the Announce does not exist.

  ## Examples

      iex> get_announce!(123)
      %Announce{}

      iex> get_announce!(456)
      ** (Ecto.NoResultsError)

  """
  def get_announce!(id), do: Repo.get!(Announce, id)

  @doc """
  Creates a announce.

  ## Examples

      iex> create_announce(%{field: value})
      {:ok, %Announce{}}

      iex> create_announce(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_announce(attrs \\ %{}) do
    %Announce{}
    |> Announce.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a announce.

  ## Examples

      iex> update_announce(announce, %{field: new_value})
      {:ok, %Announce{}}

      iex> update_announce(announce, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_announce(%Announce{} = announce, attrs) do
    announce
    |> Announce.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Announce.

  ## Examples

      iex> delete_announce(announce)
      {:ok, %Announce{}}

      iex> delete_announce(announce)
      {:error, %Ecto.Changeset{}}

  """
  def delete_announce(%Announce{} = announce) do
    Repo.delete(announce)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking announce changes.

  ## Examples

      iex> change_announce(announce)
      %Ecto.Changeset{source: %Announce{}}

  """
  def change_announce(%Announce{} = announce) do
    Announce.changeset(announce, %{})
  end
end
