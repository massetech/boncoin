defmodule Boncoin.ContentsTest do
  use Boncoin.DataCase
  import Boncoin.Factory
  alias Boncoin.Contents
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce, Image, TrafficKpi}

  describe "familys" do
    @valid_attrs %{active: true, title_my: "some title_my", title_en: "some title_en", icon: "fa-test", icon_type: "fa", rank: 2}
    @update_attrs %{active: false, title_my: "some updated title_my", title_en: "some updated title_en", icon: "fa-test2", icon_type: "fas", rank: 1}
    @invalid_attrs %{active: nil, title_my: nil, title_en: nil}

    test "list_familys/0 returns all familys" do
      [family_0, family_1, family_2] = insert_list(3, :family)
      list = Contents.list_familys()
      assert Enum.count(list, fn x -> x.id == family_0.id end) > 0
      assert Enum.count(list, fn x -> x.id == family_1.id end) > 0
      assert Enum.count(list, fn x -> x.id == family_2.id end) > 0
    end

    test "get_family!/1 returns the family with given id" do
      family = insert(:family)
      assert Contents.get_family!(family.id) == family
    end

    test "create_family/1 with valid data creates a family" do
      assert {:ok, %Family{} = family} = Contents.create_family(@valid_attrs)
      assert family.active == true
      assert family.title_my == "some title_my"
      assert family.title_en == "some title_en"
      assert family.icon == "fa-test"
      assert family.icon_type == "fa"
      assert family.rank == 2
    end

    test "create_family/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_family(@invalid_attrs)
    end

    test "update_family/2 with valid data updates the family" do
      family = insert(:family)
      assert {:ok, family} = Contents.update_family(family, @update_attrs)
      assert %Family{} = family
      assert family.active == false
      assert family.title_my == "some updated title_my"
      assert family.title_en == "some updated title_en"
      assert family.icon == "fa-test2"
      assert family.icon_type == "fas"
      assert family.rank == 1
    end

    test "update_family/2 with invalid data returns error changeset" do
      family = insert(:family)
      assert {:error, %Ecto.Changeset{}} = Contents.update_family(family, @invalid_attrs)
      assert family == Contents.get_family!(family.id)
    end

    test "delete_family/1 deletes the family" do
      family = insert(:family)
      assert {:ok, %Family{}} = Contents.delete_family(family)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_family!(family.id) end
    end

    test "change_family/1 returns a family changeset" do
      family = insert(:family)
      assert %Ecto.Changeset{} = Contents.change_family(family)
    end
  end

  describe "categorys" do
    @valid_attrs %{active: true, title_my: "some title_my", title_en: "some title_en", icon: "fa-test", icon_type: "fa", rank: 2}
    @update_attrs %{active: false, title_my: "some updated title_my", title_en: "some updated title_en", icon: "fa-test2", icon_type: "fas", rank: 1}
    @invalid_attrs %{active: nil, title_my: nil, title_en: nil}

    test "list_categorys/0 returns all categorys" do
      [category_0, category_1, category_2] = insert_list(3, :category)
      list = Contents.list_categorys()
      assert Enum.count(list, fn x -> x.id == category_0.id end) > 0
      assert Enum.count(list, fn x -> x.id == category_1.id end) > 0
      assert Enum.count(list, fn x -> x.id == category_2.id end) > 0
    end

    test "get_category!/1 returns the category with given id" do
      category = insert(:category)
      assert Contents.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      family = insert(:family)
      assert {:ok, %Category{} = category} = Contents.create_category(Map.put(@valid_attrs, :family_id, family.id))
      assert category.active == true
      assert category.title_my == "some title_my"
      assert category.title_en == "some title_en"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = insert(:category)
      assert {:ok, category} = Contents.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.active == false
      assert category.title_my == "some updated title_my"
      assert category.title_en == "some updated title_en"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = insert(:category)
      assert {:error, %Ecto.Changeset{}} = Contents.update_category(category, @invalid_attrs)
      assert category == Contents.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = insert(:category)
      assert {:ok, %Category{}} = Contents.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = insert(:category)
      assert %Ecto.Changeset{} = Contents.change_category(category)
    end
  end

  describe "townships" do
    @valid_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_my: "some title_my", title_en: "some title_en"}
    @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_my: "some updated title_my", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_my: nil, title_en: nil}

    test "list_townships/0 returns all townships" do
      [township_0, township_1, township_2] = insert_list(3, :township)
      list = Contents.list_townships()
      assert Enum.count(list, fn x -> x.id == township_0.id end) > 0
      assert Enum.count(list, fn x -> x.id == township_1.id end) > 0
      assert Enum.count(list, fn x -> x.id == township_2.id end) > 0
    end

    test "get_township!/1 returns the township with given id" do
      township = insert(:township)
      assert Contents.get_township!(township.id) == township
    end

    test "create_township/1 with valid data creates a township" do
      division = insert(:division)
      assert {:ok, %Township{} = township} = Contents.create_township(Map.put(@valid_attrs, :division_id, division.id))
      assert township.active == true
      assert township.latitute == "some latitute"
      assert township.longitude == "some longitude"
      assert township.title_my == "some title_my"
      assert township.title_en == "some title_en"
    end

    test "create_township/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_township(@invalid_attrs)
    end

    test "update_township/2 with valid data updates the township" do
      township = insert(:township)
      assert {:ok, township} = Contents.update_township(township, @update_attrs)
      assert %Township{} = township
      assert township.active == false
      assert township.latitute == "some updated latitute"
      assert township.longitude == "some updated longitude"
      assert township.title_my == "some updated title_my"
      assert township.title_en == "some updated title_en"
    end

    test "update_township/2 with invalid data returns error changeset" do
      township = insert(:township)
      assert {:error, %Ecto.Changeset{}} = Contents.update_township(township, @invalid_attrs)
      assert township == Contents.get_township!(township.id)
    end

    test "delete_township/1 deletes the township" do
      township = insert(:township)
      assert {:ok, %Township{}} = Contents.delete_township(township)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_township!(township.id) end
    end

    test "change_township/1 returns a township changeset" do
      township = insert(:township)
      assert %Ecto.Changeset{} = Contents.change_township(township)
    end
  end

  describe "divisions" do
    @valid_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_my: "some title_my", title_en: "some title_en"}
    @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_my: "some updated title_my", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_my: nil, title_en: nil}

    test "list_divisions/0 returns all divisions" do
      [division_0, division_1, division_2] = insert_list(3, :division)
      list = Contents.list_divisions()
      assert Enum.count(list, fn x -> x.id == division_0.id end) > 0
      assert Enum.count(list, fn x -> x.id == division_1.id end) > 0
      assert Enum.count(list, fn x -> x.id == division_2.id end) > 0
    end

    test "get_division!/1 returns the division with given id" do
      division = insert(:division)
      assert Contents.get_division!(division.id) == division
    end

    test "create_division/1 with valid data creates a division" do
      assert {:ok, %Division{} = division} = Contents.create_division(@valid_attrs)
      assert division.active == true
      assert division.latitute == "some latitute"
      assert division.longitude == "some longitude"
      assert division.title_my == "some title_my"
      assert division.title_en == "some title_en"
    end

    test "create_division/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_division(@invalid_attrs)
    end

    test "update_division/2 with valid data updates the division" do
      division = insert(:division)
      assert {:ok, division} = Contents.update_division(division, @update_attrs)
      assert %Division{} = division
      assert division.active == false
      assert division.latitute == "some updated latitute"
      assert division.longitude == "some updated longitude"
      assert division.title_my == "some updated title_my"
      assert division.title_en == "some updated title_en"
    end

    test "update_division/2 with invalid data returns error changeset" do
      division = insert(:division)
      assert {:error, %Ecto.Changeset{}} = Contents.update_division(division, @invalid_attrs)
      assert division == Contents.get_division!(division.id)
    end

    test "delete_division/1 deletes the division" do
      division = insert(:division)
      assert {:ok, %Division{}} = Contents.delete_division(division)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_division!(division.id) end
    end

    test "change_division/1 returns a division changeset" do
      division = insert(:division)
      assert %Ecto.Changeset{} = Contents.change_division(division)
    end
  end

  # describe "announces" do
  #   alias Boncoin.Contents.Announce
  #   @valid_attrs %{conditions: true, description: "some description", language: "some language", latitute: "some latitute", longitude: "some longitude", photo1: "some photo1", photo2: "some photo2", photo3: "some photo3", price: 120.5, status: "some status", title: "some title", validity_date: "2010-04-17 14:00:00.000000Z"}
  #   @update_attrs %{conditions: false, description: "some updated description", language: "some updated language", latitute: "some updated latitute", longitude: "some updated longitude", photo1: "some updated photo1", photo2: "some updated photo2", photo3: "some updated photo3", price: 456.7, status: "some updated status", title: "some updated title", validity_date: "2011-05-18 15:01:01.000000Z"}
  #   @invalid_attrs %{conditions: nil, description: nil, language: nil, latitute: nil, longitude: nil, photo1: nil, photo2: nil, photo3: nil, price: nil, status: nil, title: nil, validity_date: nil}
  #
  #   test "list_announces/0 returns all announces" do
  #     announce = insert_list(5, :announce)
  #     assert Enum.count(Contents.list_announces()) == Enum.count(announce)
  #   end
  #
  #   test "get_announce!/1 returns the announce with given id" do
  #     announce = insert(:announce)
  #     assert Contents.get_announce!(announce.id) == announce
  #   end
  #
  #   test "create_announce/1 with valid data creates a announce" do
  #     assert {:ok, %Announce{} = announce} = Contents.create_announce(@valid_attrs)
  #     assert announce.conditions == true
  #     assert announce.description == "some description"
  #     assert announce.language == "some language"
  #     assert announce.latitute == "some latitute"
  #     assert announce.longitude == "some longitude"
  #     assert announce.photo1 == "some photo1"
  #     assert announce.photo2 == "some photo2"
  #     assert announce.photo3 == "some photo3"
  #     assert announce.price == 120.5
  #     assert announce.status == "some status"
  #     assert announce.title == "some title"
  #     assert announce.validity_date == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
  #   end
  #
  #   test "create_announce/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Contents.create_announce(@invalid_attrs)
  #   end
  #
  #   test "update_announce/2 with valid data updates the announce" do
  #     announce = insert(:announce)
  #     assert {:ok, announce} = Contents.update_announce(announce, @update_attrs)
  #     assert %Announce{} = announce
  #     assert announce.conditions == false
  #     assert announce.description == "some updated description"
  #     assert announce.language == "some updated language"
  #     assert announce.latitute == "some updated latitute"
  #     assert announce.longitude == "some updated longitude"
  #     assert announce.photo1 == "some updated photo1"
  #     assert announce.photo2 == "some updated photo2"
  #     assert announce.photo3 == "some updated photo3"
  #     assert announce.price == 456.7
  #     assert announce.status == "some updated status"
  #     assert announce.title == "some updated title"
  #     assert announce.validity_date == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
  #   end
  #
  #   test "update_announce/2 with invalid data returns error changeset" do
  #     announce = insert(:announce)
  #     assert {:error, %Ecto.Changeset{}} = Contents.update_announce(announce, @invalid_attrs)
  #     assert announce == Contents.get_announce!(announce.id)
  #   end
  #
  #   test "delete_announce/1 deletes the announce" do
  #     announce = insert(:announce)
  #     assert {:ok, %Announce{}} = Contents.delete_announce(announce)
  #     assert_raise Ecto.NoResultsError, fn -> Contents.get_announce!(announce.id) end
  #   end
  #
  #   test "change_announce/1 returns a announce changeset" do
  #     announce = insert(:announce)
  #     assert %Ecto.Changeset{} = Contents.change_announce(announce)
  #   end
  # end

  describe "images" do
    @describetag :letest
    @valid_attrs %{file: Announce.image_param_example()}
    @update_attrs %{file: Announce.image_param_example()}
    @invalid_attrs %{file: ""}

    test "list_images/0 returns all images" do
      announce = insert(:announce)
      {:ok, image1} = Contents.create_image(Map.put(@valid_attrs, :announce_id, announce.id))
      {:ok, image2} = Contents.create_image(Map.put(@valid_attrs, :announce_id, announce.id))
      {:ok, image3} = Contents.create_image(Map.put(@valid_attrs, :announce_id, announce.id))
      list = Contents.list_images()
      assert Enum.count(list, fn x -> x.id == image1.id end) > 0
      assert Enum.count(list, fn x -> x.id == image2.id end) > 0
      assert Enum.count(list, fn x -> x.id == image3.id end) > 0
    end

    test "get_image!/1 returns the image with given id" do
      announce = insert(:announce)
      {:ok, image} = Contents.create_image(Map.put(@valid_attrs, :announce_id, announce.id))
      image_saved = Contents.get_image!(image.id)
      assert image_saved.id == image.id
    end

    test "create_image/1 with valid data creates a image" do
      announce = insert(:announce)
      assert {:ok, %Image{} = image} = Contents.create_image(Map.put(@valid_attrs, :announce_id, announce.id))
      assert image.announce_id == announce.id
    end

    # test "create_image/1 with invalid data returns error changeset" do
    #   assert {:error, %Ecto.Changeset{}} = Contents.create_image(@valid_attrs)
    # end

    # test "delete_image/1 deletes the image" do
    #   image = insert(:image)
    #   assert {:ok, %Image{}} = Contents.delete_image(image)
    #   assert_raise Ecto.NoResultsError, fn -> Contents.get_image!(image.id) end
    # end
  end

end
