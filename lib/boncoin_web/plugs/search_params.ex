defmodule Boncoin.Plug.SearchParams do
  import Plug.Conn
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    IO.puts("search_params IN")
    IO.inspect(conn.params)
    case Map.has_key?(conn.params, "search") do
      true ->
        category_id = case Map.has_key?(conn.params["search"], "category_id") do
          true -> conn.params["search"]["category_id"]
          false -> nil
        end
        family_id = case Map.has_key?(conn.params["search"], "family_id") do
          true -> if Kernel.is_nil(category_id) == true, do: conn.params["search"]["family_id"], else: Contents.get_category!(category_id).family_id
          false -> if Kernel.is_nil(category_id) == true, do: nil, else: Contents.get_category!(category_id).family_id
        end
        township_id = case Map.has_key?(conn.params["search"], "township_id") do
          true -> conn.params["search"]["township_id"]
          false -> nil
        end
        division_id = case Map.has_key?(conn.params["search"], "division_id") do
          true -> if Kernel.is_nil(township_id) == true, do: conn.params["search"]["division_id"], else: Contents.get_township!(township_id).division_id
          false -> if Kernel.is_nil(township_id) == true, do: nil, else: Contents.get_township!(township_id).division_id
        end
        search_params = %{family_id: family_id, category_id: conn.params["search"]["category_id"], division_id: division_id, township_id: conn.params["search"]["township_id"]}
      false ->
        # No search is given : we initiate the params
        search_params = %{family_id: nil, category_id: nil, division_id: nil, township_id: nil}
    end
    IO.puts("search_params OUT")
    IO.inspect(search_params)
    assign(conn, :search_params, search_params)
  end
end
