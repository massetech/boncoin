defmodule Boncoin.Etag do
  import Plug.Conn
  use BoncoinWeb, :controller

  def render_or_cache(conn, view, html, data) do
    version = "#{Application.spec(:boncoin, :vsn)}"
    conn = conn
      |> put_resp_header("cache-control", "max-age=60")
      |> put_resp_header("etag", "#{Application.spec(:boncoin, :vsn)}")

    case get_req_header(conn, "if-none-match") do
      [version] ->
        IO.puts("not reloaded")
        send_resp(conn, 304, "")
      _ -> render(conn, view, html, data)
    end
  end

end
