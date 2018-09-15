defmodule BoncoinWeb.UserController do
  use BoncoinWeb, :controller
  alias Boncoin.Members
  alias Boncoin.Members.User
  import Boncoin.CustomModules

  def index(conn, _params) do
    users = Members.list_users()
    render(conn, "index.html", users: users)
  end

  # API to ba called for a phone number on announce page
  def check_phone(conn, %{"scope" => scope, "params" => phone_number} = params) do
    IO.inspect(params)
    case scope do
      "get_phone_details" ->
        answer = Members.read_phone_details(phone_number)
        case answer do
          {:ok, user} ->
            if is_list(user.announces), do: nb_offers = Kernel.length(user.announces), else: nb_offers = 0
            results = %{scope: scope, data: %{user: user, nb_offers: nb_offers}, error: ""}
            render(conn, "phone_api.json", results: results)
          {:error, msg} ->
            results = %{scope: scope, data: %{}, error: msg}
            render(conn, "phone_api.json", results: results)
        end
    end
  end

  def new(conn, _params) do
    changeset = Members.change_user(%User{})
    roles = Members.User.role_select_btn()
    languages = Members.User.language_select_btn()
    render(conn, "new.html", changeset: changeset, roles: roles, languages: languages)
  end

  def create(conn, %{"user" => user_params}) do
    case Members.create_user(user_params) do
      {:ok, user} ->
        conn
          |> put_flash(:info, "User created successfully.")
          |> put_status(308)
          |> redirect(to: user_path(conn, :index))
          |> halt()
      {:error, %Ecto.Changeset{} = changeset} ->
        roles = Members.User.role_select_btn()
        languages = Members.User.language_select_btn()
        error = get_changeset_error(changeset)
        conn
          |> put_flash(:info, "Errors, please check.")
          |> render("new.html", changeset: changeset, languages: languages, roles: roles)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Members.get_user!(id)
    {:ok, _user} = Members.delete_user(user)
    conn
    |> put_flash(:info, "USer deleted successfully.")
    |> put_status(308)
    |> redirect(to: user_path(conn, :index))
    |> halt()
  end
end
