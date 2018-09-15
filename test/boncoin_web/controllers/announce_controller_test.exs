defmodule BoncoinWeb.AnnounceControllerTest do
  use BoncoinWeb.ConnCase
  alias Boncoin.Contents
  alias Boncoin.Contents.Announce
  import Boncoin.Factory

  @create_attrs %{conditions: true, description: "some description", language: "some language", image_file_1: Announce.image_param_example(), image_file_2: "", image_file_3: "", price: 120.5, title: "some title"}
  @update_attrs %{conditions: false, description: "some updated description", language: "some updated language", image_file_1: Announce.image_param_example(), image_file_2: "", image_file_3: "", price: 456.7, title: "some updated title"}
  @invalid_attrs %{conditions: nil, description: nil, language: nil, photo1: nil, photo2: nil, photo3: nil, price: nil, status: nil, title: nil}
  @moduletag :AnnounceController
  @moduletag :Controller

  describe "admin" do
    @describetag :admin_authenticated
    test "lists all announces in dashboard", %{conn: conn} do
      conn = get conn, announce_path(conn, :index)
      assert html_response(conn, 200) =~ "Offers"
    end

    test "deletes chosen announce from dashboard", %{conn: conn} do
      announce = insert(:announce)
      conn = delete conn, announce_path(conn, :delete, announce)
      assert html_response(conn, 308)
      assert get_flash(conn, :info) == "Offer deleted successfully."
    end
  end

  describe "public" do
    test "list announces in public view", %{conn: conn} do
      list = insert_list(11, :announce)
        |> Enum.reverse() # Reverse since the sorting order will be in date decreasing
      first_offer_shown = List.first(list)
      last_offer_shown = Enum.at(list, 9)
      last_offer = List.last(list)
      conn = get conn, public_offers_path(conn, :public_index)
      assert html_response(conn, 200) =~ "offers-results", "wrong page"
      assert html_response(conn, 200) =~ "big_announce_#{first_offer_shown.id}", "First offer is missing"
      assert html_response(conn, 200) =~ "big_announce_#{last_offer_shown.id}", "Last offer shown is missing"
      refute html_response(conn, 200) =~ "big_announce_#{last_offer.id}", "Last offer should not be published"
      assert html_response(conn, 200) =~ "11 offers found", "wrong counting of total offers"
    end

    test "load more offers from the API load more", %{conn: conn} do
      list = insert_list(21, :announce)
        |> Enum.reverse() # Reverse since the sorting order will be in date decreasing
      first_offer_shown = Enum.at(list, 10)
      last_offer_shown = Enum.at(list, 19)
      last_offer = List.last(list)
      # First call for loading page
      conn1 = get conn, public_offers_path(conn, :public_index)
      cursor_after = conn1.assigns.cursor_after
      # Call 2nd time to load more offers
      data = %{"scope" => "anything", "params" => %{"cursor_after" => cursor_after, "search_params" => %{"category_id" => "", "division_id" => "", "family_id" => "", "township_id" => ""}}}
      result = conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", conn1.assigns.api_key)
        |> post("/api/add_offers", data)
      resp_body = result.resp_body
        |> Poison.decode!()
      resp_html = resp_body["results"]["data"]["offers"]
        |> Stream.map(fn %{"display_big" => big, "display_small" => small} -> small end)
        |> Enum.join()
        # |> IO.inspect(limit: :infinity, printable_limit: :infinity)
      assert result.status == 200, "wrong status code returned"
      assert resp_html =~ "small_announce_#{first_offer_shown.id}", "First offer is missing in 2nd call"
      assert resp_html =~ "small_announce_#{last_offer_shown.id}", "Last offer shown is missing in 2nd call"
      refute resp_html =~ "small_announce_#{last_offer.id}", "Last offer should not be published in 2nd call"
    end
  end

  describe "new announce" do
    test "renders form", %{conn: conn} do
      conn = get conn, announce_path(conn, :new)
      assert html_response(conn, 200) =~ "Fill your details"
    end
  end

  describe "create announce" do
    test "redirects to public offers when data is valid", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 302) =~ "/offers?search[township_id]"
      assert get_flash(conn, :info) == "Announce created successfully."
    end

    test "renders errors when user is guest", %{conn: conn} do
      user = insert(:user, %{role: "GUEST", phone_number: "09020102010"})
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please choose another phone number."
    end

    test "renders errors when title is empty", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{title: "", user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please put a title to your offer."
    end

    test "renders errors when description is empty", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{description: "", user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please write a description of your offer."
    end

    test "renders errors when price is empty", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{price: "", user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please give a price to your offer."
    end

    test "renders errors when surname is empty", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{surname: "", user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please fill your name or surname."
    end

    test "renders errors when no photo is given", %{conn: conn} do
      user = insert(:member_user)
      township = insert(:township)
      category = insert(:category)
      conn = post conn, announce_path(conn, :create), announce: Map.merge(@create_attrs, %{image_file_1: "", user_id: user.id, township_id: township.id, category_id: category.id})
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please post at least one photo."
    end
  end

  describe "show announce" do
    @tag :admin_authenticated
    test "to admin", %{conn: conn} do
      offer = insert(:announce)
      conn = get conn, announce_path(conn, :show, offer.id)
      assert html_response(conn, 200) =~ "show_admin_offer_#{offer.id}"
    end

    @tag :member_authenticated
    test "returns on landing page for non admin user", %{conn: conn} do
      offer = insert(:announce)
      conn = get conn, announce_path(conn, :show, offer.id)
      assert html_response(conn, 308)
      assert get_flash(conn, :alert) == "You must be admin to access that part."
    end

    test "returns on landing page for non authenticated user", %{conn: conn} do
      offer = insert(:announce)
      conn = get conn, announce_path(conn, :show, offer.id)
      assert html_response(conn, 308)
      assert get_flash(conn, :alert) == "You must be logged in to access that part."
    end
  end

  describe "edit announce" do
    test "ONLINE for owner user member", %{conn: conn} do
      offer = insert(:announce)
      safe_link = Cipher.encrypt(Integer.to_string(offer.id))
      {:ok, offer} = Contents.update_announce(offer, %{safe_link: safe_link})
      conn = get conn, announce_path(conn, :edit, offer.safe_link)
      assert html_response(conn, 200) =~ "show_user_offer_#{offer.id}"
    end
    test "CLOSED for owner user member", %{conn: conn} do
      offer = insert(:announce, %{status: "CLOSED"})
      safe_link = Cipher.encrypt(Integer.to_string(offer.id))
      {:ok, offer} = Contents.update_announce(offer, %{safe_link: safe_link})
      conn = get conn, announce_path(conn, :edit, offer.safe_link)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "This announce is now closed."
    end
    test "with broken link", %{conn: conn} do
      offer = insert(:announce, %{safe_link: "whatever_wrong_link"})
      conn = get conn, announce_path(conn, :edit, offer.safe_link)
      assert html_response(conn, 302)
      assert get_flash(conn, :alert) == "Sorry this link is broken."
    end
    test "remove offer by user", %{conn: conn} do
      offer = insert(:announce)
      conn = get conn, announce_path(conn, :close, announce_id: offer.id, cause: "SOLD")
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Your offer has been removed."
    end
  end


  # describe "update announce" do
  #   setup [:create_announce]
  #
  #   test "redirects when data is valid", %{conn: conn, announce: announce} do
  #     conn = put conn, announce_path(conn, :update, announce), announce: @update_attrs
  #     assert redirected_to(conn) == announce_path(conn, :show, announce)
  #
  #     conn = get conn, announce_path(conn, :show, announce)
  #     assert html_response(conn, 200) =~ "some updated description"
  #   end
  #
  #   test "renders errors when data is invalid", %{conn: conn, announce: announce} do
  #     conn = put conn, announce_path(conn, :update, announce), announce: @invalid_attrs
  #     assert html_response(conn, 200) =~ "Edit Announce"
  #   end
  # end

end
