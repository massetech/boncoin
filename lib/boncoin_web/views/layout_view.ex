defmodule BoncoinWeb.LayoutView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  # def switch_locale_path(conn, locale, language) do
  #   # "<a href=\"#{page_path(conn, :index, locale: :en)}\">#{language}</a>" |> raw
  #   # "<a class='text-dark' href=\"?locale=#{locale}\">#{language}</a>" |> raw
  #   # "<a href=\"#{page_path(conn, :index, locale: :en)}\">#{language}</a>" |> raw
  #   "<a href=\"?locale=#{locale}\">#{language}</a>" |> raw
  # end

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

end
