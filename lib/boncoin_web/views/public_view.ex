defmodule BoncoinWeb.PublicView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView
  # import PhoenixETag

  # def stale_checks("welcome." <> _format, %{nb_announces: nb_announces}) do
  #   [etag: schema_etag(nb_announces), last_modified: schema_last_modified(nb_announces)]
  # end

  # def stale_checks("conditions." <> _format, %{}) do
  #   []
  # end

end
