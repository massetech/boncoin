defmodule BoncoinWeb.LayoutView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView
  # import PhoenixGon.View
  alias Boncoin.Members

  # def switch_locale_path(conn, locale, language) do
  #   # "<a href=\"#{page_path(conn, :index, locale: :en)}\">#{language}</a>" |> raw
  #   # "<a class='text-dark' href=\"?locale=#{locale}\">#{language}</a>" |> raw
  #   # "<a href=\"#{page_path(conn, :index, locale: :en)}\">#{language}</a>" |> raw
  #   "<a href=\"?locale=#{locale}\">#{language}</a>" |> raw
  # end

  def check_admin(user) do
    if Members.admin_user?(user), do: true, else: false
  end

  def icon_active(status) do
    case status do
      true -> "<i class='fa fa-check-circle text-success'></>" |> raw
      false -> "<i class='fa fa-times-circle text-warning'></>" |> raw
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
        "#{year}/#{day}/#{month}-#{hour}:#{minute}"
    end
  end

  def format_date(datetime) do
    case datetime do
      nil -> ""
      datetime ->
        day = datetime.day
        month = datetime.month
        year = datetime.year
        "#{year}/#{day}/#{month}"
    end
  end

  def show_inline_price(price, currency) do
    "#{price} #{currency}"
  end

  def convert_zawgyi(text) do
    case Gettext.get_locale() do
      "en" -> text
      "my" -> text
      "mr" -> Rabbit.uni2zg(text)
    end
  end

  def convert_zawgyi(map, key) do
    case Gettext.get_locale() do
      "en" -> Map.fetch!(map, String.to_atom("#{key}_en"))
      "my" -> Map.fetch!(map, String.to_atom("#{key}_my"))
      "mr" ->
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
