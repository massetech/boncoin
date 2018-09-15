# @tag :internal_api
# test "get more offers from the API load more", %{conn: conn} do
#   insert_list(21, :announce)
#   # First loading of page
#   conn1 = get conn, public_offers_path(conn, :public_index)
#   api_key = conn1.assigns.api_key
#   cursor_after = conn1.assigns.cursor_after
#   # Call from button load more
#   data = %{"scope" => "anything", "params" => %{"cursor_after" => cursor_after, "search_params" => %{}}}
#   resp = HTTPotion.post "/api/add_offers", body: Poison.encode!(data), headers: [
#     "accept": "application/json", "content-type": "application/json", "Authorization": conn1.assigns.api_key]
#   |> IO.inspect()
#   # assert resp.status == 200
#   # assert response.status_code == 200
# end
