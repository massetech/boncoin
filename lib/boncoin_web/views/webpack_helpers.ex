defmodule BoncoinWeb.WebpackHelpers do
  alias BoncoinWeb.Router.Helpers, as: Routes

  def js_script_tag(conn) do
    if Mix.env == :prod do
      Routes.static_path(conn, "/js/app.js")
    else
      webpack_path(conn, '/js/app.js')
    end
  end

  def css_link_tag(conn) do
    if Mix.env == :prod do
      Routes.static_path(conn, "/css/app.css")
    else
      webpack_path(conn, '/css/app.css')
    end
  end

  def img_url_tag(conn, file_path) do
    if Mix.env == :prod do
      Routes.static_path(conn, "/images/#{file_path}")
    else
      webpack_path(conn, '/images/#{file_path}')
    end
  end

  def webpack_path(conn, path) do
    if Mix.env == :prod do
      Routes.static_path(conn, path)
    else
      # all assets (including output bundles) are served with
      # `webpack-dev-server` in development
      "http://localhost:8080#{path}"
    end
  end

end
