defmodule BoncoinWeb.UserController do
  use BoncoinWeb, :controller
  alias Boncoin.{Members, Contents}
  alias Boncoin.Members.User
  alias Boncoin.Contents.Announce

  def index(conn, _params) do
    users = Members.list_users()
    render(conn, "index.html", users: users)
  end

  def embassador(conn, %{"id" => user_id} = params) do
    user = Members.get_user!(user_id)
    calendar = %{year_now: Kernel.inspect(Timex.now().year), month_now: Kernel.inspect(Timex.now().month), years: Boncoin.CustomModules.list_of_years(), months: Boncoin.CustomModules.list_of_months()}
    filter = if params["filter"] == nil, do: %{month: calendar.month_now, year: calendar.year_now}, else: %{month: params["filter"]["month"], year: params["filter"]["year"]}
    data = Members.get_embassador_kpi(user_id, filter)
    conversation = Members.get_conversation_by_user_id(user_id)
    render(conn, "embassador.html", user: user, conversation: conversation, filter: filter, calendar: calendar, data: data)
  end

  # API to ba called for a phone number on announce page
  def check_phone(conn, %{"scope" => scope, "params" => phone_number}) do
    case Members.read_phone_details(phone_number) do
      {:ok, user} ->
        nb_offers = if is_list(user.announces), do: Kernel.length(user.announces), else: 0
        results = %{scope: scope, data: %{user: user, nb_offers: nb_offers}, error: ""}
        render(conn, "phone_api.json", results: results)
      {:new_user, user} ->
        results = %{scope: scope, data: %{user: user, nb_offers: 0}, error: ""}
        render(conn, "phone_api.json", results: results)
      {:error, msg} ->
        results = %{scope: scope, data: %{}, error: msg}
        render(conn, "phone_api.json", results: results)
    end
  end

  # def new(conn, _params) do
  #   changeset = Members.change_user(%User{})
  #   roles = Members.User.role_select_btn()
  #   languages = Members.User.language_select_btn()
  #   render(conn, "new.html", changeset: changeset, roles: roles, languages: languages)
  # end

  # def create(conn, %{"user" => user_params}) do
  #   case Members.create_and_track_user(user_params) do
  #     {:ok, _user} ->
  #       conn
  #         |> put_flash(:info, "User created successfully.")
  #         |> redirect(to: Routes.user_path(conn, :index))
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       roles = Members.User.role_select_btn()
  #       languages = Members.User.language_select_btn()
  #       conn
  #         |> put_flash(:info, "Errors, please check.")
  #         |> render("new.html", changeset: changeset, languages: languages, roles: roles)
  #   end
  # end

  def new_user_announce(conn, _params) do
    changeset = Members.change_user(%User{announces: [%Announce{}]})
    conn
      |> render("new_user_announce.html", changeset: changeset)
  end

  def new_user_announce_with_phone(conn, %{"phone_number" => phone_number} = params) do
    offer_params = if Map.has_key?(params, "offer_params"), do: params["offer_params"], else: %{}
    case User.check_myanmar_phone_number(phone_number) do
      true ->
        offer_changeset = Announce.changeset(%Announce{}, offer_params)
        changeset = Members.change_user(%User{phone_number: phone_number, announces: [offer_changeset]})
        conn
          |> render("new_user_announce.html", changeset: changeset)
      false -> redirect(conn, to: Routes.user_path(conn, :new_user_announce))
    end
  end

  def create_announce(conn, %{"user" => params}) do
    case Members.create_user_announce(params) do
      {:ok, announce} ->
        township = Contents.get_township!(announce.township_id)
        conn
          |> put_flash(:info, gettext("Your offer was created. We will treat it soon."))
          |> redirect(to: Routes.public_offers_path(conn, :public_index, search: %{division_id: township.division_id}))
      {:error, %Ecto.Changeset{} = changeset} ->
        %{"phone_number" => phone_number, "announces" => %{"0" => offer_params}} = params
        offer_params = Map.drop(offer_params, ["image_file_1", "image_file_2", "image_file_3"])
        conn
          |> put_flash(:alert, Announce.show_errors_in_msg(changeset))
          |> redirect(to: Routes.user_path(conn, :new_user_announce_with_phone, phone_number, offer_params: offer_params))
      {:error, msg} -> # When the user doesn't exist or is not found
        %{"phone_number" => phone_number, "announces" => %{"0" => offer_params}} = params
        offer_params = Map.drop(offer_params, ["image_file_1", "image_file_2", "image_file_3"])
        conn
          |> put_flash(:alert, msg)
          |> redirect(to: Routes.user_path(conn, :new_user_announce_with_phone, phone_number, offer_params: offer_params))
    end
  end

  def edit(conn, %{"id" => id}) do
    user = Members.get_user!(id)
    changeset = Members.change_user(user)
    roles = Members.User.role_select_btn()
    render(conn, "edit.html", user: user, changeset: changeset, roles: roles)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Members.get_user!(id)
    roles = Members.User.role_select_btn()
    case Members.update_user(user, user_params) do
      {:ok, _division} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(:info, "Errors, please check.")
        |> render("edit.html", user: user, changeset: changeset, roles: roles)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Members.get_user!(id)
    {:ok, _user} = Members.delete_user(user)
    conn
      |> put_flash(:info, "User deleted successfully.")
      |> redirect(to: Routes.user_path(conn, :index))
  end
end
