defmodule Boncoin.Plug.SearchParams do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    # IO.puts("search_params IN")
    # IO.inspect(conn.params)

    new_search_map = case Map.has_key?(conn.params, "search") do
      true -> conn.params["search"]
      false -> %{} # Nothing will happen on the merge
    end
    old_search_map = case Map.has_key?(conn.params, "old_search") do
      true -> conn.params["old_search"]
      false -> %{} # Nothing will happen on the merge
    end

    search_params = %{"family_id" => "", "category_id" => "", "division_id" => "", "township_id" => ""}
      |> Map.merge(old_search_map) # We start by old search to keep between pages old_search: @conn.assigns.search_params)
      |> Map.merge(new_search_map)
      |> resolve_township_conflicts()
      |> resolve_category_conflicts()

    search_titles = %{
      searched_place: build_searched_place(search_params["division_id"], search_params["township_id"]),
      searched_arbo: build_searched_arbo(search_params["family_id"], search_params["category_id"])
    }

    # Count KPI searches by township
    if search_params["township_id"] != "" && (search_params["family_id"] != "" || search_params["category_id"] != "") do
      Contents.add_kpi_township_traffic(search_params["township_id"], "new_search")
    end

    conn
      |> assign(:search_params, search_params)
      |> assign(:search_titles, search_titles)
  end

  defp build_searched_arbo(family_id, category_id) do
    case family_id do
      "" ->
        %{title_my: "", title_en: ""}
      id ->
        family = Contents.get_family!(family_id)
        case category_id do
          "" ->
            %{title_my: "#{family.title_my}", title_en: "#{family.title_en}"}
          id ->
            category = Contents.get_category!(category_id)
            %{title_my: "#{category.title_my}", title_en: "#{category.title_en}"}
        end
    end
  end

  defp build_searched_place(division_id, township_id) do
    case division_id do
      "" ->
        %{title_my: "ပောပဒနိ", title_en: "All Myanmar"}
      id ->
        division = Contents.get_division!(division_id)
        case township_id do
          "" ->
            %{title_my: "ဒသဉ #{division.title_my}", title_en: "#{division.title_en}"}
          id ->
            township = Contents.get_township!(township_id)
            %{title_my: "#{division.title_my} - #{township.title_my}", title_en: "#{division.title_en} - #{township.title_en}"}
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
