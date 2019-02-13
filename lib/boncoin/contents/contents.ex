defmodule Boncoin.Contents do
  import Ecto.Query, warn: false
  alias Boncoin.{Repo, Members}
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce, Image, TrafficKpi}
  alias Boncoin.Members.{User}
  alias Boncoin.CustomModules.BotDecisions

  # -------------------------------- TRAFFIC KPI ----------------------------------------

  def add_kpi_township_traffic(township_id, type) do
    # date_now = Timex.now()
    # date_now = DateTime.utc_now()
    date_now = Date.utc_today()
    add_new_guest = if type == "new_user", do: 1, else: 0
    add_old_guest = if type == "old_user", do: 1, else: 0
    add_search = if type == "new_search", do: 1, else: 0
    add_more = if type == "add_more", do: 1, else: 0
    kpi = TrafficKpi
      # |> TrafficKpi.select_township_traffic_kpi_by_date(township_id, %Date{date_now.year, date_now.month, date_now.day})
      |> TrafficKpi.select_township_traffic_kpi_by_date(township_id, date_now)
      |> Repo.one()
    case kpi do
      nil -> %TrafficKpi{} # Not yet any record for this township / date
        |> TrafficKpi.changeset(
          %{township_id: township_id, date: date_now,
          nb_new_guest: add_new_guest,
          nb_old_guest: add_old_guest,
          nb_cat_searches: add_search,
          nb_click_add_more: add_more}
        )
      traffic_kpi -> traffic_kpi # Already record for this township / date
        |> TrafficKpi.changeset(
          %{township_id: township_id, date: date_now,
          nb_new_guest: traffic_kpi.nb_new_guest + add_new_guest,
          nb_old_guest: traffic_kpi.nb_old_guest + add_old_guest,
          nb_cat_searches: traffic_kpi.nb_cat_searches + add_search,
          nb_click_add_more: traffic_kpi.nb_click_add_more + add_more}
        )
    end
    |> Repo.insert_or_update

  end

  def create_traffic_kpi(attrs \\ %{}) do
    %TrafficKpi{}
      |> TrafficKpi.changeset(attrs)
      |> Repo.insert()
  end

  def update_traffic_kpi(%TrafficKpi{} = traffic_kpi, attrs) do
    traffic_kpi
      |> TrafficKpi.changeset(attrs)
      |> Repo.update()
  end

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

  def list_townships_active do
    Township
      |> Township.filter_townships_active()
      |> Repo.all()
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

  def get_township(id) do
    Repo.get(Township, id)
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

  def list_divisions do
    Division
      |> Repo.all()
  end

  def list_divisions_for_select() do
    Division
      |> Division.select_divisions_for_dropdown()
      |> Repo.all()
  end

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
      |> Repo.preload([:images, :category, township: [:division], user: [:conversation]])
  end

  def filter_announces_liked_online(id_list) do
    Announce
      |> Announce.filter_announces_id_list_online(id_list)
      |> Announce.select_announce_id()
      |> Repo.all()
  end

  # def list_announces_public_liked(id_list) do
  #   user_query = User
  #     |> User.filter_user_public_data()
  #   Announce
  #     |> Announce.filter_announces_id_list_online(id_list)
  #     |> Announce.select_announces_datas(user_query)
  #     |> Repo.all()
  # end

  def list_announces_public(cursor_after, %{category_id: category_id, division_id: division_id, family_id: family_id, township_id: township_id}) do
    user_query = User
      |> User.filter_user_public_data()
    offer_query = Announce
      |> Announce.filter_announces_online()
      |> Announce.filter_announces_by_location(division_id, township_id)
      |> Announce.filter_announces_by_kind(family_id, category_id)
      |> Announce.sort_announces_for_pagination()
      |> Announce.select_announces_datas(user_query)
    # Process.sleep(3000)
    case cursor_after do # Format %{entries: entries, metadata: metadata}
      nil -> # Call the first time
        Repo.paginate(offer_query, cursor_fields: [:priority, :parution_date], sort_direction: :desc)
      _ -> # load more entries
        Repo.paginate(offer_query, after: cursor_after, cursor_fields: [:priority, :parution_date], sort_direction: :desc)
    end
  end

  def count_announces_public() do
    Announce
      |> Announce.count_announces_online()
      |> Repo.one()
  end

  def get_user_active_offers(user) do
    Announce
      |> Announce.select_user_active_offers(user)
      |> Repo.all()
  end

  def get_user_online_offers(user) do
    Announce
      |> Announce.select_user_online_offers(user)
      |> Repo.all()
      |> Repo.preload([:images])
  end

  def get_announce!(id) do
    Repo.get!(Announce, id)
      |> Repo.preload([:user, :images, township: [:division], category: [:family]])
  end

  def create_announce(attrs \\ %{}, user_id) do
    params = attrs
      |> Map.merge(%{"status" => "PENDING", "user_id" => user_id}) # Make sure the offer is on pending
    offer = %Announce{}
      |> Announce.changeset(params)
      |> Repo.insert()
    case offer do
      {:ok, announce} ->
        # Loop on the 3 photo fields of the form params
        for i <- ["image_file_1", "image_file_2", "image_file_3"] do
          unless attrs[i] == "" do
            create_announce_image(announce.id, attrs[i])
          end
        end
        # Send a message to admin that a new announce was posted
        Members.inform_admin_by_viber(:new_offer, nil)
        {:ok, announce}
      error_offer -> error_offer
    end
  end

  def treat_announce(admin_user, %{"announce_id" => announce_id, "validate" => validate, "cause" => cause_label, "category_id" => category_id} = params) do
    announce = get_announce!(announce_id)
    user = Members.get_user(announce.user_id)
    user_msg = if validate == "true", do: "", else: select_user_msg_for_offer_treatment(announce, user, cause_label)
    status = if validate == "true", do: "ONLINE", else: select_status_for_offer_treatment(announce)
    dates = calc_announce_validity_date()
    params = %{treated_by_id: admin_user.id, status: status, cause: cause_label, category_id: category_id, parution_date: dates.parution_date, validity_date: dates.validity_date}
    case update_announce(announce, params) do
      {:ok, updated_announce} ->
        cond do
          user.conversation.active == true && announce.status == "PENDING" -> # Bot msg for new offers
            # Flag the user first offer date if offer accepted (embassador KPI)
            if validate == "true", do: Members.flag_first_user_offer(user)
            # Send bot message to user
            %{user: user, conversation: Map.put(user.conversation, :scope, "offer_treated"), announce: updated_announce, user_msg: user_msg}
              |> BotDecisions.call_bot_algorythm()
              |> Members.send_bot_message_to_user(updated_announce, :update)
          user.conversation.active == true && status == "CLOSED" -> # Bot msg for old offers closed by admin
            %{user: user, conversation: Map.put(user.conversation, :scope, "offer_closed"), announce: updated_announce, user_msg: user_msg}
              |> BotDecisions.call_bot_algorythm()
              |> Members.send_bot_message_to_user(updated_announce, :update)
          # true -> {:ok, "no message sent (not Bot for this user)", []} # User is not bot active : do nothing
        end
      {:error, msg} -> {:error, msg, []}
    end
  end

  defp select_user_msg_for_offer_treatment(announce, user, cause) do
    if announce.status == "PENDING" do
      Announce.refusal_causes()
        |> Enum.find(&(&1.label == cause))
        |> convert_user_msg_to_zawgyi(user.language)
    else
      Announce.admin_closing_causes()
        |> Enum.find(&(&1.label == cause))
        |> convert_user_msg_to_zawgyi(user.language)
    end
  end

  defp select_status_for_offer_treatment(announce) do
    if announce.status == "PENDING", do: "REFUSED", else: "CLOSED"
  end

  defp convert_user_msg_to_zawgyi(msg_map, user_lg) do
    uni = msg_map.user_msg_my
    case user_lg do
      "en" -> msg_map.user_msg_en
      "my" -> uni
      "mr" -> Rabbit.uni2zg(uni)
    end
  end

  defp calc_announce_validity_date() do
    parution_date = Timex.now()
    validity_date = Timex.shift(parution_date, months: 1)
    %{parution_date: parution_date, validity_date: validity_date}
  end

  def add_alert_to_announce(announce_id) do
    case Repo.get(Announce, announce_id) do
      nil -> {:error, "offer not found"}
      offer -> update_announce(offer, %{nb_alert: offer.nb_alert + 1})
    end
  end

  def add_clic_to_announce(announce_id) do
    case Repo.get(Announce, announce_id) do
      nil -> {:error, "offer not found"}
      offer -> update_announce(offer, %{nb_clic: offer.nb_clic + 1})
    end
  end

  def update_announce(%Announce{} = announce, attrs) do
    announce
      |> Announce.changeset(attrs)
      |> Repo.update()
  end

  # def add_safe_link_to_last_offer(announce) do
  #   # Encrypt announce ID and generate a safe_link
  #   update_announce(announce, %{"safe_link" => Announce.build_safe_link(announce.id)})
  # end

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

  def list_images do
    Repo.all(Image)
  end

  def get_image!(id), do: Repo.get!(Image, id)

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

  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  def change_image(%Image{} = image) do
    Image.changeset(image, %{})
  end
end
