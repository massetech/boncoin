defmodule BoncoinWeb.ViberView do
  use BoncoinWeb, :view

  def render("confirm_answer.json", %{status: status}) do
    %{status: status}
  end

  def render("send_message.json", %{sender: sender, message: message, tracking_data: tracking_data}) do
    %{
      sender: sender,
      type: "text",
      text: message,
      tracking_data: tracking_data
    }
  end

end
