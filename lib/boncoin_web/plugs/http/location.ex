defmodule Boncoin.Plug.Location do
  import Plug.Conn
  import Boncoin.{Gettext}
  alias Boncoin.Contents

  def init(_opts), do: nil

  def call(conn, _opts) do
    # By default we take params, then cookies which results in nil if no cookie set
    township_cookie = town_from_cookies(conn)
    township = if town_from_params(conn) != "", do: town_from_params(conn), else: township_cookie
    previous_visit? = Map.has_key?(conn.cookies, "visit") # This cookie disapears after 24h

    case township do
      nil ->  # First time that we see this visitor
        conn
          # |> Phoenix.Controller.put_flash(:info, gettext("Info that we are using cookies."))
          |> put_resp_cookie("town", "", max_age: 60 * 60 * 24 * 365)
      "" -> # No indication on the visitor's township
        # IO.puts("township unknown")
        conn
      township_id -> # We know the visitor's township
        cond do
          previous_visit? == true -> # Already a visit cookie less than 24h : don't count this visit
            IO.puts("kpi not counted : already visited")
          previous_visit? == false && township_cookie == "" -> # New user never seen
            IO.puts("kpi counted : new user visiting")
            Contents.add_kpi_township_traffic(township_id, "new_user")
          previous_visit? == false -> # User already seen
            IO.puts("kpi counted : old user comming back")
            Contents.add_kpi_township_traffic(township_id, "old_user")
        end
        conn |> add_visit_to_conn(township_id)
    end
  end

  defp town_from_params(conn) do
    conn.assigns.search_params["township_id"] #|> validate_town()
  end
  defp town_from_cookies(conn) do
    conn.cookies["town"] #|> validate_town()
  end
  # defp validate_town(town), do: town
  # defp validate_town(_locale), do: nil

  defp add_visit_to_conn(conn, township_id) do
    conn
      |> put_resp_cookie("town", township_id, max_age: 60 * 60 * 24 * 365) # 1 year
      |> put_resp_cookie("visit", "counted", max_age: 60 * 60 * 24) # 24h
  end

end
