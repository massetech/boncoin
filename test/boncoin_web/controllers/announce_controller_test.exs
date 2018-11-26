defmodule BoncoinWeb.AnnounceControllerTest do
  use BoncoinWeb.ConnCase
  alias Boncoin.{Contents, ViberApi, MessengerApi}
  alias Boncoin.Contents.Announce
  alias BoncoinWeb.LayoutView
  import Boncoin.Factory
  import Mockery.Assertions
  use Mockery

  @create_attrs %{conditions: true, description: "some description", language: "some language", image_file_1: Announce.image_param_example(), image_file_2: "", image_file_3: "", price: "120", title: "some title"}
  @update_attrs %{conditions: false, description: "some updated description", language: "some updated language", image_file_1: Announce.image_param_example(), image_file_2: "", image_file_3: "", price: "450", title: "some updated title"}
  @invalid_attrs %{conditions: nil, description: nil, language: nil, photo1: nil, photo2: nil, photo3: nil, price: nil, status: nil, title: nil}
  @moduletag :AnnounceController
  @moduletag :Controller

  defp build_offer_params(attrs, %{phone_number: phone_number, nickname: nickname}, township_id, category_id) do
    %{user: %{
        phone_number: phone_number, nickname: nickname,
        announces: %{'0': Map.merge(attrs, %{township_id: township_id, category_id: category_id})}
      }
    }
  end

  describe "admin" do
    @describetag :admin_authenticated
    test "lists all announces in dashboard", %{conn: conn} do
      conn = get conn, announce_path(conn, :index)
      assert html_response(conn, 200) =~ "Offers"
    end
    test "treats offer : ACCEPTED / ONLINE and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE"})
      offer = insert(:announce, %{user_id: user.id, status: "PENDING"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: true, cause: "ACCEPTED", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      # msg = "Hi Mr unknown, your offer an offer title is now published !\nIt will be online for 1 month until #{LayoutView.format_date(new_offer.validity_date)}.\nYou can manage your offer on"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "ONLINE"
      assert new_offer.cause == "ACCEPTED"
      assert_called ViberApi, :send_message, ["123RENE", _msg], 1
    end
    test "treats offer : ACCEPTED / ONLINE and send Messenger msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "messenger", bot_id: "123RENE2"})
      offer = insert(:announce, %{user_id: user.id, status: "PENDING"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: true, cause: "ACCEPTED", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      # msg = "Hi Mr unknown, your offer an offer title is now published !\nIt will be online for 1 month until #{LayoutView.format_date(new_offer.validity_date)}.\nYou can manage your offer on"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Messenger"
      assert new_offer.status == "ONLINE"
      assert new_offer.cause == "ACCEPTED"
      assert_called MessengerApi, :send_message, ["123RENE2", _msg], 1
    end
    test "treats offer : NOT_ALLOWED / REFUSED and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE3"})
      offer = insert(:announce, %{user_id: user.id, status: "PENDING"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: false, cause: "NOT_ALLOWED", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      msg = "Hi Mr unknown, we are sorry but your offer an offer title was refused because its content is not allowed.. \nPlease create a new one on https://www.pawchaungkaung.com/offer/new/09000000000"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "REFUSED"
      assert new_offer.cause == "NOT_ALLOWED"
      assert_called ViberApi, :send_message, ["123RENE3", ^msg], 1
    end
    test "treats offer : UNCLEAR / REFUSED and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE4"})
      offer = insert(:announce, %{user_id: user.id, status: "PENDING"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: false, cause: "UNCLEAR", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      msg = "Hi Mr unknown, we are sorry but your offer an offer title was refused because its description is not clear.. \nPlease create a new one on https://www.pawchaungkaung.com/offer/new/09000000000"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "REFUSED"
      assert new_offer.cause == "UNCLEAR"
      assert_called ViberApi, :send_message, ["123RENE4", ^msg], 1
    end
    test "treats offer : BAD_PHOTOS / REFUSED and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE5"})
      offer = insert(:announce, %{user_id: user.id, status: "PENDING"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: false, cause: "BAD_PHOTOS", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      msg = "Hi Mr unknown, we are sorry but your offer an offer title was refused because the photos are not good.. \nPlease create a new one on https://www.pawchaungkaung.com/offer/new/09000000000"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "REFUSED"
      assert new_offer.cause == "BAD_PHOTOS"
      assert_called ViberApi, :send_message, ["123RENE5", ^msg], 1
    end
    test "treats offer : ADMIN_DECISION / CLOSED and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE6"})
      offer = insert(:announce, %{user_id: user.id, status: "ONLINE"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: false, cause: "ADMIN_DECISION", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      msg = "Hi Mr unknown, your offer an offer title has been closed following an admin decision.. \nPlease create a new one on https://www.pawchaungkaung.com/offer/new/09000000000"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "CLOSED"
      assert new_offer.cause == "ADMIN_DECISION"
      assert_called ViberApi, :send_message, ["123RENE6", ^msg], 1
    end
    test "treats offer : TIME_PASSED / CLOSED and send Viber msg", %{conn: conn} do
      user = insert(:user, %{bot_provider: "viber", bot_id: "123RENE7"})
      offer = insert(:announce, %{user_id: user.id, status: "ONLINE"})
      conn = get conn, announce_path(conn, :treat, %{announce_id: offer.id, validate: false, cause: "TIME_PASSED", category_id: offer.category_id})
      new_offer = Contents.get_announce!(offer.id)
      msg = "Hi Mr unknown, your offer an offer title has been closed after its publication time.. \nPlease create a new one on https://www.pawchaungkaung.com/offer/new/09000000000"
      assert get_flash(conn, :info) == "Offer treated and message sent to user by Viber"
      assert new_offer.status == "CLOSED"
      assert new_offer.cause == "TIME_PASSED"
      assert_called ViberApi, :send_message, ["123RENE7", ^msg], 1
    end
    test "deletes chosen announce from dashboard", %{conn: conn} do
      announce = insert(:announce)
      conn = delete conn, announce_path(conn, :delete, announce)
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Offer deleted successfully."
    end
  end

  describe "public" do
    test "list announces in public view", %{conn: conn} do
      list = insert_list(21, :announce)
        |> Enum.reverse() # Reverse since the sorting order will be in date decreasing
      first_offer_shown = List.first(list)
      last_offer_shown = Enum.at(list, 19)
      last_offer = List.last(list)
      conn = get conn, public_offers_path(conn, :public_index)
      assert html_response(conn, 200) =~ "offers-results", "wrong page"
      assert html_response(conn, 200) =~ "offer_#{first_offer_shown.id}", "First offer is missing"
      assert html_response(conn, 200) =~ "offer_#{last_offer_shown.id}", "Last offer shown is missing"
      refute html_response(conn, 200) =~ "offer_#{last_offer.id}", "Last offer should not be published"
      assert html_response(conn, 200) =~ "21 offers found", "wrong counting of total offers"
    end

    test "load more offers from the API load more", %{conn: conn} do
      list = insert_list(41, :announce)
        |> Enum.reverse() # Reverse since the sorting order will be in date decreasing
      first_offer_shown = Enum.at(list, 20)
      last_offer_shown = Enum.at(list, 39)
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
      resp_html = resp_body["results"]["data"]["offers"]["inline_html"]
        # |> Stream.map(fn %{"display_big" => big, "display_small" => small} -> small end)
        # |> Enum.join()
        # |> IO.inspect(limit: :infinity, printable_limit: :infinity)
      assert result.status == 200, "wrong status code returned"
      assert resp_html =~ "offer_#{first_offer_shown.id}", "First offer is missing in loading more call"
      assert resp_html =~ "offer_#{last_offer_shown.id}", "Last offer shown is missing in loading more call"
      refute resp_html =~ "offer_#{last_offer.id}", "Last offer should not be published in loading more call"
    end
  end

  describe "new user creates announce" do
    test "renders errors when phone number is guest", %{conn: conn} do
      user_params = %{phone_number: "09000000000", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please check your phone number."
    end
    test "redirects to public offers when data is valid", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000111"})
      user_params = %{phone_number: "09000000111", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 302) =~ "/offer/index?search[township_id]"
      assert get_flash(conn, :info) == "Your offer was created. We will treat it soon."
    end
    test "renders errors when title is empty", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000112"})
      user_params = %{phone_number: "09000000112", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{title: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please put a title to your offer."
    end
    test "renders errors when description is empty", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000113"})
      user_params = %{phone_number: "09000000113", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{description: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please write a description of your offer."
    end
    test "renders errors when price is empty", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000114"})
      user_params = %{phone_number: "09000000114", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{price: "sz"}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please give a price to your offer."
    end
    test "renders errors when no photo is given", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000115"})
      user_params = %{phone_number: "09000000115", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{image_file_1: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please post at least one photo."
    end
    test "renders errors when user surname is empty", %{conn: conn} do
      user_params = %{phone_number: "09000000116", nickname: ""}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please check your name or nickname."
    end
    test "renders errors when user is not linked to bot", %{conn: conn} do
      user = insert(:member_user, %{phone_number: "09000000117", bot_active: false})
      user_params = %{phone_number: "09000000117", nickname: "some_nickname"}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "You must link to Viber or Messenger to create an offer."
    end
  end

  describe "existing user creates announce" do
    test "renders errors when user surname is empty", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000110"})
      user_params = %{phone_number: user.phone_number, nickname: ""}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please check your name or nickname."
    end

    test "redirects to public offers when data is valid", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000111"})
      user_params = %{phone_number: user.phone_number, nickname: user.nickname}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(@create_attrs, user_params, township.id, category.id)
      assert html_response(conn, 302) =~ "/offer/index?search[township_id]"
      assert get_flash(conn, :info) == "Your offer was created. We will treat it soon."
    end

    test "renders errors when title is empty", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000112"})
      user_params = %{phone_number: user.phone_number, nickname: user.nickname}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{title: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please put a title to your offer."
    end

    test "renders errors when description is empty", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000113"})
      user_params = %{phone_number: user.phone_number, nickname: user.nickname}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{description: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please write a description of your offer."
    end

    test "renders errors when price is empty", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000114"})
      user_params = %{phone_number: user.phone_number, nickname: user.nickname}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{price: "dede"}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please give a price to your offer."
    end

    test "renders errors when no photo is given", %{conn: conn} do
      user = insert(:user, %{phone_number: "09000000115"})
      user_params = %{phone_number: user.phone_number, nickname: user.nickname}
      township = insert(:township)
      category = insert(:category)
      conn = post conn, user_path(conn, :create_announce), build_offer_params(Map.merge(@create_attrs, %{image_file_1: ""}), user_params, township.id, category.id)
      assert html_response(conn, 200) =~ "Fill your details"
      assert get_flash(conn, :alert) == "Please post at least one photo."
    end
  end

  # describe "show announce" do
  #   @tag :admin_authenticated
  #   test "to admin", %{conn: conn} do
  #     offer = insert(:announce, %{title: "dede"})
  #     conn = get conn, announce_path(conn, :show, offer.id)
  #     assert html_response(conn, 200) =~ "dede"
  #   end

    # @tag :member_authenticated
    # test "returns on landing page for non admin user", %{conn: conn} do
    #   offer = insert(:announce)
    #   conn = get conn, announce_path(conn, :show, offer.id)
    #   assert html_response(conn, 308)
    #   assert get_flash(conn, :alert) == "You must be admin to access that part."
    # end

    # test "returns on landing page for non authenticated user", %{conn: conn} do
    #   offer = insert(:announce)
    #   conn = get conn, announce_path(conn, :show, offer.id)
    #   assert html_response(conn, 308)
    #   assert get_flash(conn, :alert) == "You must be logged in to access that part."
    # end
  # end

  describe "show user announce" do
    test "shows the offer when it is ONLINE", %{conn: conn} do
      offer = insert(:announce, %{title: "dede"})
      # safe_link = Cipher.encrypt(Integer.to_string(offer.id))
      # {:ok, offer} = Contents.update_announce(offer, %{safe_link: safe_link})
      url = Cipher.sign_url("http://localhost:4001/#{announce_path(conn, :show, offer.id)}")
      conn = get conn, url
      assert html_response(conn, 200) =~ "dede"
    end
    test "redirects when the offer is CLOSED", %{conn: conn} do
      offer = insert(:announce, %{status: "CLOSED"})
      # safe_link = Cipher.encrypt(Integer.to_string(offer.id))
      # {:ok, offer} = Contents.update_announce(offer, %{safe_link: safe_link})
      # conn = get conn, announce_path(conn, :show, offer.safe_link)
      url = Cipher.sign_url("http://localhost:4001/#{announce_path(conn, :show, offer.id)}")
      conn = get conn, url
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "This offer is no more published."
    end
    test "redirects with broken link", %{conn: conn} do
      # offer = insert(:announce, %{safe_link: "whatever_wrong_link"})
      offer = insert(:announce)
      # conn = get conn, announce_path(conn, :show, offer.safe_link)
      url = Cipher.sign_url("http://localhost:4001/#{announce_path(conn, :show, offer.id)}")
        |> String.replace("b", "") # Removes all the "b" from the string
        |> String.replace("y", "") # Removes all the "b" from the string
        |> String.replace("z", "") # Removes all the "b" from the string
      conn = get conn, url
      assert html_response(conn, 302)
      assert get_flash(conn, :alert) == "Sorry, this offer doesn't exist or the link is broken."
    end
    test "remove offer by user", %{conn: conn} do
      offer = insert(:announce)
      conn = get conn, announce_path(conn, :close, announce_id: offer.id, cause: "SOLD")
      assert html_response(conn, 302)
      assert get_flash(conn, :info) == "Your offer has been closed and is no more online."
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
