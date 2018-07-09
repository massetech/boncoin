defmodule BoncoinWeb.PageController do
  use BoncoinWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
