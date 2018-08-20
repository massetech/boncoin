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
  end

  defp choosen_category(%{"category_id" => category_id}) do
    case category_id do
      "" -> ""
      category_id -> Contents.get_category!(category_id)
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
