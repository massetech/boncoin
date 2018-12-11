defmodule Boncoin.Etag do
  import Plug.Conn
  use BoncoinWeb, :controller

  def render_or_cache(conn, view, template, assigns) do
    version = "#{Application.spec(:boncoin, :vsn)}"
    flash_msg = get_flash(conn)
    if flash_msg == %{} do
      # IO.puts("no flash msg : cached")
      conn = conn
        |> put_resp_header("cache-control", "max-age=1") # Same page will be asked again after 1 min
        |> put_resp_header("etag", "#{Application.spec(:boncoin, :vsn)}") # Etag is the app version
        |> put_view(view)
        # |> render(template, assigns) # Only for dev purpose
      case get_req_header(conn, "if-none-match") do
        [version] -> send_resp(conn, 304, "")
        _ -> render(conn, template, assigns)
      end
    else
      # Don't play with cache if there is flash messages
      # IO.puts("flash msg : not cached")
      conn = conn
        |> put_view(view)
        |> render(template, assigns)
    end
  end

end
