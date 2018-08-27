defmodule Boncoin.Plug.SearchParams do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    # IO.puts("search_params IN")
    # IO.inspect(conn.params)

    case Map.has_key?(conn.params, "search") do
      true -> new_search_map = conn.params["search"]
      false -> new_search_map = %{} # Nothing will happen on the merge
    end
    case Map.has_key?(conn.params, "old_search") do
      true -> old_search_map = conn.params["old_search"]
      false -> old_search_map = %{} # Nothing will happen on the merge
    end

    search_params = %{"family_id" => "", "category_id" => "", "division_id" => "", "township_id" => ""}
      |> Map.merge(old_search_map)
      |> Map.merge(new_search_map)
      |> resolve_township_conflicts()
      |> resolve_category_conflicts()

    # IO.puts("search_params OUT")
    # IO.inspect(search_params)
    conn
      |> assign(:search_params, search_params)
      |> assign(:category, choosen_category(search_params))
      |> assign(:family, choosen_family(search_params))
      |> assign(:place_searched, build_place_searched(search_params["division_id"], search_params["township_id"]))
  end

  defp build_place_searched(division_id, township_id) do
    case division_id do
      "" ->
        %{title_my: "ပောပဒနိ", title_en: "All Myanmar"}
      id ->
        division = Contents.get_division!(division_id)
        case township_id do
          "" ->
            %{title_my: "ဒသဉ #{division.title_my}", title_en: "#{String.upcase(division.title_en)}"}
          id ->
            township = Contents.get_township!(township_id)
            %{title_my: "#{division.title_my} - #{township.title_my}", title_en: "#{String.upcase(division.title_en)} - #{township.title_en}"}
        end
    end
  end

  defp choosen_category(%{"category_id" => category_id}) do
    case category_id do
      "" -> ""
      category_id -> Contents.get_category!(category_id)
    end
  end

  defp choosen_family(%{"family_id" => family_id}) do
    case family_id do
      "" -> ""
      family_id -> Contents.get_family!(family_id)
    end
  end

  defp resolve_township_conflicts(%{"township_id" => township_id} = params) do
    case township_id do
      "" -> params
      township_id ->
        # Use the division_id corresponding to township_id
        division_id = Contents.get_township!(township_id).division_id
          |> Integer.to_string()
        Map.merge(params, %{"division_id" => division_id})
    end
  end

  defp resolve_category_conflicts(%{"category_id" => category_id} = params) do
    case category_id do
      "" -> params
      category_id ->
        # Use the family_id corresponding to category_id
        family_id = Contents.get_category!(category_id).family_id
          |> Integer.to_string()
        Map.merge(params, %{"family_id" => family_id})
    end
  end
end