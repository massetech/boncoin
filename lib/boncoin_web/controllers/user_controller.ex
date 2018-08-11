defmodule BoncoinWeb.UserController do
  use BoncoinWeb, :controller
  alias Boncoin.Members
  alias Boncoin.Members.User

  def index(conn, _params) do
    users = Members.list_users()
    render(conn, "index.html", users: users)
  end

  def check_phone(conn, %{"scope" => scope, "phone_number" => phone_number}) do
    case scope do
      "get_phone_details" ->
        answer = Members.read_phone_details(phone_number)
        case answer do
          {:ok, user} ->
            data = %{scope: scope, user_id: user.id, user_nickname: user.nickname, email: user.email, viber_active: user.viber_active, nb_announces: Kernel.length(user.announces)}
            render(conn, "phone_api_ok.json", data: data)
          {:error, msg} -> render(conn, "phone_api_nok.json", msg: msg)
        end
      "unlink_viber" ->
        answer = Members.unlink_viber(phone_number)
        case answer do
          {:ok, user} ->
            data = %{scope: scope}
            render(conn, "phone_api_ok.json", data: data)
          {:error, msg} -> render(conn, "phone_api_nok.json", msg: msg)
        end
    end
  end

  def new(conn, _params) do
    changeset = Members.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Members.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
  #
  # def show(conn, %{"id" => id}) do
  #   user = Members.get_user!(id)
  #   render(conn, "show.html", user: user)
  # end
  #
  # def edit(conn, %{"id" => id}) do
  #   user = Members.get_user!(id)
  #   changeset = Members.change_user(user)
  #   render(conn, "edit.html", user: user, changeset: changeset)
  # end
  #
  # def update(conn, %{"id" => id, "user" => user_params}) do
  #   user = Members.get_user!(id)
  #
  #   case Members.update_user(user, user_params) do
  #     {:ok, user} ->
  #       conn
  #       |> put_flash(:info, "User updated successfully.")
  #       |> redirect(to: user_path(conn, :show, user))
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       render(conn, "edit.html", user: user, changeset: changeset)
  #   end
  # end

  def delete(conn, %{"id" => id}) do
    user = Members.get_user!(id)
    {:ok, _user} = Members.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end
end
