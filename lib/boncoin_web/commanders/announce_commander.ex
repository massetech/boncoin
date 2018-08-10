defmodule BoncoinWeb.AnnounceCommander do
  use Drab.Commander
  alias Boncoin.{Contents, Members}
  alias BoncoinWeb.ViberController

  public [:read_user_details, :remove_viber_link]
  onload :page_loaded

  def page_loaded(socket) do
    socket |> exec_js("console.log('Alert from the other side!');")
  end

  def remove_viber_link(socket, payload) do
    %{"announce" => %{"user_id" => user_id}} = payload.params
    user = Members.get_user!(user_id)
    case Members.remove_viber_id(user) do
      {:ok, _user} ->
        socket
          |> exec_js("console.log('viber removed for this user');")
          # Build response msg with the bot
          {tracking_data, message} = %{tracking_data: "viber_removed", user: %{db_user: user, language: user.language, viber_id: user.viber_id, viber_name: user.nickname, user_msg: ""}, announce: nil}
            |> ViberController.call_bot_algorythm()
          # Send the message to viber API
          ViberController.send_viber_message(user.viber_id, tracking_data, message)
          # Update the announce page
          socket
            |> exec_js("remove_viber_btn_after_unlink();")
      {:error, _} ->
        socket
          |> exec_js("window.alert('Sorry there is a problem.');")
    end
  end

  # def read_user_details(socket, payload) do
  #   %{"announce" => %{"phone_number" => phone_number}} = payload.params
  #   # IO.inspect(phone_number)
  #   cond do
  #     String.match?(phone_number, ~r/^([09]{1})([0-9]{10})$/) ->
  #       # The number is a Myanmar mobile number
  #       user = Members.get_user_or_create_by_phone_number(phone_number)
  #       # |> IO.inspect()
  #       case user do
  #         nil -> # Something went wrong on user creation
  #           socket
  #           |> exec_js("reset_announce_form_field();")
  #           # |> exec_js("validate_phone_number_field();")
  #         user -> # The user is found
  #           # if user.password == "", do: password = false, else: password = true end
  #           password = true
  #           socket
  #           |> exec_js("validate_phone_number_pop_field('#{user.id}', '#{user.nickname}', '#{user.email}', '#{password}', '#{user.viber_active}', '#{Kernel.length(user.announces)}');")
  #       end
  #     true ->
  #       # The number is NOT a Myanmar mobile number
  #       socket
  #       |> exec_js("reset_announce_form_field();")
  #   end
  # end
end
