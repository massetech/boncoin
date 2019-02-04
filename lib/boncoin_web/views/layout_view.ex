defmodule BoncoinWeb.LayoutView do
  use BoncoinWeb, :view
  alias Boncoin.Members

  def check_admin(user) do
    if Members.admin_user?(user), do: true, else: false
  end

  def show_month(month) do
    case month do
      "1" -> "January"
      "2" -> "February"
      "3" -> "March"
      "4" -> "April"
      "5" -> "May"
      "6" -> "June"
      "7" -> "July"
      "8" -> "August"
      "9" -> "September"
      "10" -> "October"
      "11" -> "November"
      "12" -> "December"
    end
  end

  def display_alert(message) do
    message
      |> convert_zawgyi()
      |> text_to_html([attributes: [class: "m-0 text-white font-s-12"]])
      # |> safe_to_string()
  end

  def test_lg(iso2code, nb) do
    case nb do
      1 -> if iso2code == "en", do: "sidebar-active", else: ""
      2 -> if iso2code == "my", do: "sidebar-active", else: ""
      3 -> if iso2code == "dz", do: "sidebar-active", else: ""
    end
  end

  def test_division(search_params, division_id) do
    cond do
      search_params.division_id == "" && division_id == nil -> "sidebar-active"
      search_params.division_id == Kernel.inspect(division_id) -> "sidebar-active"
      true -> ""
    end
  end

  def test_township(search_params, division_id, township_id) do
    cond do
      search_params.division_id == Kernel.inspect(division_id) && search_params.township_id == "" && township_id == nil -> "sidebar-active"
      search_params.division_id == Kernel.inspect(division_id) && search_params.township_id == Kernel.inspect(township_id) -> "sidebar-active"
      true -> ""
    end
  end

  def insert_icon_classes(model) do
    "#{model.icon_type} fa-#{model.icon}"
  end

  def show_family_selector(conn, family) do
    case family do
      nil -> if conn.assigns.search_params.family_id == "", do: "border-bottom-lg", else: ""
      _ -> if conn.assigns.search_params.family_id == Integer.to_string(family.id), do: "border-bottom-lg", else: ""
    end
  end

  def show_category_selector(conn, family, category) do
    case category do
      nil -> if conn.assigns.search_params.family_id == Integer.to_string(family.id) && conn.assigns.search_params.category_id == "", do: "btn-primary", else: "btn-outline-primary"
      _ -> if conn.assigns.search_params.category_id == Integer.to_string(category.id), do: "btn-primary", else: "btn-outline-primary"
    end
  end

  # if @conn.assigns.search_params.family_id == Integer.to_string(family.id) && @conn.assigns.search_params["category_id"] == "" do

  def icon_active(status) do
    case status do
      true -> "<i class='fa fa-check-circle text-success d-none d-sm-block'></>" |> raw
      false -> "<i class='fa fa-times-circle text-danger d-none d-sm-block'></>" |> raw
    end
  end

  def format_datehour(datetime) do
    case datetime do
      nil -> ""
      datetime ->
        day = datetime.day
        month = datetime.month
        year = datetime.year
        hour = datetime.hour
        minute = datetime.minute
        "#{year}/#{month}/#{day}-#{hour}:#{minute}"
    end
  end

  def format_date(datetime) do
    case datetime do
      nil -> ""
      datetime ->
        day = datetime.day
        month = datetime.month
        year = datetime.year
        "#{year}/#{month}/#{day}"
    end
  end

  def show_phone_number(phone_number) do
    "#{String.slice(phone_number, 0..1)} #{String.slice(phone_number, 2..4)} #{String.slice(phone_number, 5..7)} #{String.slice(phone_number, 8..10)}"
  end

  # def show_viber_number(viber_number) do
  #   "+959 #{String.slice(viber_number, 2..4)} #{String.slice(viber_number, 5..7)} #{String.slice(viber_number, 8..10)}"
  # end

  # Added &# to avoid the auto css on number for iphone
  def show_inline_price(price, currency) do
    "#{String.slice(price, 0..4)}&#{String.slice(price, 5..8)}&#{String.slice(price, 9..10)} #{currency}"
  end

  def convert_zawgyi(text) do
    case Gettext.get_locale() do
      "en" -> text
      "my" -> text
      "dz" -> Rabbit.uni2zg(text)
    end
  end

  def convert_lg_title(map, key) do
    case Gettext.get_locale() do
      "en" -> Map.fetch!(map, String.to_atom("#{key}_en"))
      _ -> Map.fetch!(map, String.to_atom("#{key}_my"))
    end
  end

  def convert_zawgyi(map, key) do
    case Gettext.get_locale() do
      "en" -> Map.fetch!(map, String.to_atom("#{key}_en"))
      "my" -> Map.fetch!(map, String.to_atom("#{key}_my"))
      "dz" ->
        Map.fetch!(map, String.to_atom("#{key}_my"))
        |> Rabbit.uni2zg()
    end
  end

  @doc """
  Generates name for the JavaScript view we want to use
  in this combination of view/template.
  """
  def js_view_name(conn, view_template) do
    [view_name(conn), template_name(view_template)]
      |> Enum.reverse
      |> List.insert_at(0, "view")
      |> Enum.map(&String.capitalize/1)
      |> Enum.reverse
      |> Enum.join("")
  end

  # Takes the resource name of the view module and removes the
  # the ending *_view* string.
  defp view_name(conn) do
    conn
      |> view_module
      |> Phoenix.Naming.resource_name
      |> String.replace("_view", "")
  end

  # Removes the extion from the template and reutrns
  # just the name.
  defp template_name(template) when is_binary(template) do
    template
      |> String.split(".")
      |> Enum.at(0)
  end

end
