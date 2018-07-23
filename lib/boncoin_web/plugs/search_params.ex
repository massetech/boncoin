defmodule Boncoin.Plug.SearchParams do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    IO.puts("search_params IN")
    IO.inspect(conn.params)

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

    # case Map.has_key?(conn.params, "search") do
    #   true ->
    #     category_id = case Map.has_key?(conn.params["search"], "category_id") do
    #       true -> conn.params["search"]["category_id"]
    #       false -> nil
    #     end
    #     family_id = case Map.has_key?(conn.params["search"], "family_id") do
    #       true -> if Kernel.is_nil(category_id) == true, do: conn.params["search"]["family_id"], else: Contents.get_category!(category_id).family_id
    #       false -> if Kernel.is_nil(category_id) == true, do: nil, else: Contents.get_category!(category_id).family_id
    #     end
    #     township_id = case Map.has_key?(conn.params["search"], "township_id") do
    #       true -> conn.params["search"]["township_id"]
    #       false -> nil
    #     end
    #     division_id = case Map.has_key?(conn.params["search"], "division_id") do
    #       true -> if Kernel.is_nil(township_id) == true, do: conn.params["search"]["division_id"], else: Contents.get_township!(township_id).division_id
    #       false -> if Kernel.is_nil(township_id) == true, do: nil, else: Contents.get_township!(township_id).division_id
    #     end
    #     search_params = %{family_id: family_id, category_id: conn.params["search"]["category_id"], division_id: division_id, township_id: conn.params["search"]["township_id"]}
    #   false ->
    #     # No search is given : we initiate the params
    #     search_params = %{family_id: nil, category_id: nil, division_id: nil, township_id: nil}
    # end

    IO.puts("search_params OUT")
    IO.inspect(search_params)
    conn
      |> assign(:search_params, search_params)
      |> assign(:family_icon, choose_family_icon(search_params))
  end

  defp choose_family_icon(%{"family_id" => family_id}) do
    case family_id do
      "" -> ""
      family_id -> Contents.get_family!(family_id).icon
    end
  end

  defp resolve_township_conflicts(%{"township_id" => township_id} = params) do
    case township_id do
      "" -> params
      township_id ->
        # Use the division_id corresponding to township_id
        division_id = Contents.get_township!(township_id).division_id
        Map.merge(params, %{"division_id" => division_id})
    end
  end

  defp resolve_category_conflicts(%{"category_id" => category_id} = params) do
    case category_id do
      "" -> params
      category_id ->
        # Use the family_id corresponding to category_id
        family_id = Contents.get_category!(category_id).family_id
        Map.merge(params, %{"family_id" => family_id})
    end
  end
end
