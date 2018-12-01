defmodule Boncoin.Etag do
  import Plug.Conn
  use BoncoinWeb, :controller

  def render_or_cache(conn, view, template, assigns) do
    version = "#{Application.spec(:boncoin, :vsn)}"
    conn = conn
      |> put_resp_header("cache-control", "max-age=60") # Same page will be asked again after 1 min
      |> put_resp_header("etag", "#{Application.spec(:boncoin, :vsn)}") # Etag is the app version
      |> put_view(view)
      # |> render(template, assigns) # Only for dev purpose

    case get_req_header(conn, "if-none-match") do
      [version] ->
        # IO.puts("not reloaded")
        send_resp(conn, 304, "")
      _ -> render(conn, template, assigns)
    end
  end

end
