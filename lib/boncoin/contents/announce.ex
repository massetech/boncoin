defmodule Boncoin.Contents.Announce do
  use Ecto.Schema
  import Ecto.{Query, Changeset}
  import Boncoin.Gettext
  alias Boncoin.Contents.{Category, Township, Image}
  alias Boncoin.Members.{User}
  alias Boncoin.CustomModules # Used to make some Zawgyi conversion

  schema "announces" do
    field :conditions, :boolean, default: false
    field :description, :string
    field :priority, :boolean, default: false
    field :language, :string
    field :latitute, :string
    field :longitude, :string
    field :price, :float
    field :currency, :string, default: "Kyats"
    field :status, :string, default: "PENDING"
    field :cause, :string
    field :title, :string
    field :nb_view, :integer, default: 0
    field :nb_clic, :integer, default: 0
    field :nb_alert, :integer, default: 0
    field :validity_date, :utc_datetime
    field :parution_date, :utc_datetime
    field :closing_date, :utc_datetime
    field :zawgyi, :boolean, default: false
    field :safe_link, :string
    belongs_to :treated_by, User
    belongs_to :user, User
    belongs_to :category, Category
    belongs_to :township, Township
    has_many :images, Image, on_delete: :delete_all
    timestamps()
  end

  @required_fields ~w(user_id category_id township_id title price description currency)a
  @optional_fields ~w(status cause safe_link language latitute longitude conditions nb_view nb_clic nb_alert validity_date parution_date closing_date priority zawgyi treated_by_id)a

  @doc false
  def changeset(announce, attrs) do
    params = attrs
      |> CustomModules.convert_fields_to_burmese_uni([:title, :description])
    announce
      |> cast(params, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> assoc_constraint(:user)
      |> assoc_constraint(:category)
      |> assoc_constraint(:township)
      |> validate_inclusion(:status, ["PENDING", "ONLINE", "REFUSED", "OUTDATED", "CLOSED"])
      |> validate_inclusion(:currency, ["Kyats", "Lacks", "USD"])
  end

  def check_offer_has_one_photo_min(changeset, %{"image_file_1" => picture_1, "image_file_2" => picture_2, "image_file_3" => picture_3}) do
    cond do
      picture_1 == "" && picture_2 == "" && picture_3 == "" -> # no photo on params
        changeset
          |> add_error(:photo, "no photo was given")
      true -> # at least one photo on params
        changeset
    end
  end

  def show_errors_in_msg(changeset) do
    IO.inspect(changeset)
    case List.first(changeset.errors) do
      {:surname, _msg} -> gettext("Please fill your name.")
      {:title, _msg} -> gettext("Please put a title to your offer.")
      {:price, _msg} -> gettext("Please give a price to your offer.")
      {:description, _msg} -> gettext("Please write a description of your offer.")
      {:photo, _msg} -> gettext("Please post at least one photo.")
      true -> # Something else went wrong
        gettext("Sorry wwe have a technical problem.")
    end
  end

  def status_select_btn() do
    [pending: "PENDING", accepted: "ONLINE", refused: "REFUSED", outdated: "OUTDATED", closed: "CLOSED"]
  end

  def refusal_causes() do
    [
      %{label: "NOT_ALLOWED", title: "Content not allowed", btn_color: "btn-outline-danger"},
      %{label: "UNCLEAR", title: "Description not clear", btn_color: "btn-outline-alert"},
      %{label: "BAD_PHOTOS", title: "Photos not good", btn_color: "btn-outline-alert"},
      %{label: "NO_INTEREST", title: "Offer not interesting", btn_color: "btn-outline-danger"},
      %{label: "SHOCKING", title: "Offer can shock people", btn_color: "btn-outline-danger"}
    ]
  end

  def closing_causes() do
    [
      %{label: "USER_SOLD", title: "Item was sold", btn_color: "btn-outline-info"},
      %{label: "USER_CANCELLED", title: "Offer cancelled", btn_color: "btn-outline-info"}
    ]
  end

  def admin_closing_causes() do
    [
      %{label: "ADMIN_SOLD", title: "Item was sold by user", btn_color: "btn-outline-info"},
      %{label: "ADMIN_CANCELLED", title: "Offer cancelled by user", btn_color: "btn-outline-info"},
      %{label: "ADMIN_REMOVED", title: "Offer removed by admin", btn_color: "btn-outline-danger"}
    ]
  end

  def filter_announces_online(query) do
    from a in query,
      where: a.status == "ONLINE"
  end

  def list_admin_announces(query) do
    from a in query,
      order_by: [asc: :inserted_at, desc: :parution_date, desc: :nb_clic]
  end

  def count_announces_online(query) do
    from a in query,
      where: a.status == "ONLINE",
      select: count("*")
  end

  def select_announces_datas(query, user_query) do
    from a in query,
      preload: [:images, user: ^user_query, township: [:division]]
  end

  def filter_announces_by_location(query, division_id, township_id) do
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

  def filter_announces_by_kind(query, family_id, category_id) do
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

  def select_user_offers(query, user) do
    from a in query,
      where: a.status == "ONLINE" and a.user_id == ^user.id
  end

  def sort_announces_for_pagination(query) do
    from a in query,
      order_by: [desc: a.priority, desc: a.parution_date], # Pagination is blocked on DESC
      select: a
  end

end
