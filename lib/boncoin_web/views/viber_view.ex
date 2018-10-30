defmodule BoncoinWeb.ViberView do
  use BoncoinWeb, :view

  def render("confirm_answer.json", %{status: status}) do
    %{status: status}
  end

  def render("send_message.json", %{sender: sender, message: message}) do
    %{
      sender: sender,
      type: "text",
      text: message
    }
  end

end
