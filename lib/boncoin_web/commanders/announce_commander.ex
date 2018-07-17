defmodule BoncoinWeb.AnnounceCommander do
  use Drab.Commander
  alias Boncoin.{Contents, Members}

  public [:read_user_details]
  onload :page_loaded

  def page_loaded(socket) do
    socket |> exec_js("console.log('Alert from the other side!');")
  end

  def read_user_details(socket, payload) do
    %{"announce" => %{"phone_number" => phone_number}} = payload.params
    # IO.inspect(phone_number)
    cond do
      String.match?(phone_number, ~r/^([09]{1})([0-9]{10})$/) ->
        # The number is a Myanmar mobile number
        user = Members.get_user_or_create_by_phone_number(phone_number)
        # |> IO.inspect()
        case user do
          nil -> # Something went wrong on user creation
            socket
            |> exec_js("reset_announce_form_field();")
            # |> exec_js("validate_phone_number_field();")
          user -> # The user is found
            # if user.password == "", do: password = false, else: password = true end
            password = true
            socket
            |> exec_js("validate_phone_number_pop_field('#{user.id}', '#{user.nickname}', '#{user.email}', '#{password}', '#{user.viber_active}');")
        end
      true ->
        # The number is NOT a Myanmar mobile number
        socket
        |> exec_js("reset_announce_form_field();")
    end
  end
end
