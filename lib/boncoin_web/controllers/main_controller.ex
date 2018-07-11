defmodule BoncoinWeb.MainController do
  use BoncoinWeb, :controller
  alias Boncoin.{Contents, Members}

  def welcome(conn, _params) do
    conn
      |> render(BoncoinWeb.PublicView, "welcome.html")
  end

  def public_index(conn, %{"search" => search_params} = params) do
    # IO.puts("searched public index")
    # IO.inspect(params)
    # IO.inspect(search_params)
    conn
      |> assign(:announces, Contents.list_announces_public(search_params))
      |> render(BoncoinWeb.PublicView, "announces_index.html")
  end

end
