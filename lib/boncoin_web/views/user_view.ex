defmodule BoncoinWeb.UserView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def render("phone_api_ok.json", %{data: data}) do
    %{data: data}
  end

  def render("phone_api_nok.json", %{msg: msg}) do
    %{msg: msg}
  end

end
