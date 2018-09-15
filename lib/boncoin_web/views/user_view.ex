defmodule BoncoinWeb.UserView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def render("phone_api.json", %{results: results}) do
    %{results: results}
  end
end
