defmodule Boncoin.ContentsTest do
  use Boncoin.DataCase

  alias Boncoin.Contents

  describe "familys" do
    alias Boncoin.Contents.Family

    @valid_attrs %{active: true, title_bi: "some title_bi", title_en: "some title_en"}
    @update_attrs %{active: false, title_bi: "some updated title_bi", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, title_bi: nil, title_en: nil}

    def family_fixture(attrs \\ %{}) do
      {:ok, family} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contents.create_family()

      family
    end

    test "list_familys/0 returns all familys" do
      family = family_fixture()
      assert Contents.list_familys() == [family]
    end

    test "get_family!/1 returns the family with given id" do
      family = family_fixture()
      assert Contents.get_family!(family.id) == family
    end

    test "create_family/1 with valid data creates a family" do
      assert {:ok, %Family{} = family} = Contents.create_family(@valid_attrs)
      assert family.active == true
      assert family.title_bi == "some title_bi"
      assert family.title_en == "some title_en"
    end

    test "create_family/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_family(@invalid_attrs)
    end

    test "update_family/2 with valid data updates the family" do
      family = family_fixture()
      assert {:ok, family} = Contents.update_family(family, @update_attrs)
      assert %Family{} = family
      assert family.active == false
      assert family.title_bi == "some updated title_bi"
      assert family.title_en == "some updated title_en"
    end

    test "update_family/2 with invalid data returns error changeset" do
      family = family_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_family(family, @invalid_attrs)
      assert family == Contents.get_family!(family.id)
    end

    test "delete_family/1 deletes the family" do
      family = family_fixture()
      assert {:ok, %Family{}} = Contents.delete_family(family)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_family!(family.id) end
    end

    test "change_family/1 returns a family changeset" do
      family = family_fixture()
      assert %Ecto.Changeset{} = Contents.change_family(family)
    end
  end

  describe "categorys" do
    alias Boncoin.Contents.Category

    @valid_attrs %{active: true, title_bi: "some title_bi", title_en: "some title_en"}
    @update_attrs %{active: false, title_bi: "some updated title_bi", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, title_bi: nil, title_en: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contents.create_category()

      category
    end

    test "list_categorys/0 returns all categorys" do
      category = category_fixture()
      assert Contents.list_categorys() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Contents.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Contents.create_category(@valid_attrs)
      assert category.active == true
      assert category.title_bi == "some title_bi"
      assert category.title_en == "some title_en"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, category} = Contents.update_category(category, @update_attrs)
      assert %Category{} = category
      assert category.active == false
      assert category.title_bi == "some updated title_bi"
      assert category.title_en == "some updated title_en"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_category(category, @invalid_attrs)
      assert category == Contents.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Contents.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Contents.change_category(category)
    end
  end

  describe "townships" do
    alias Boncoin.Contents.Township

    @valid_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_bi: "some title_bi", title_en: "some title_en"}
    @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_bi: "some updated title_bi", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_bi: nil, title_en: nil}

    def township_fixture(attrs \\ %{}) do
      {:ok, township} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contents.create_township()

      township
    end

    test "list_townships/0 returns all townships" do
      township = township_fixture()
      assert Contents.list_townships() == [township]
    end

    test "get_township!/1 returns the township with given id" do
      township = township_fixture()
      assert Contents.get_township!(township.id) == township
    end

    test "create_township/1 with valid data creates a township" do
      assert {:ok, %Township{} = township} = Contents.create_township(@valid_attrs)
      assert township.active == true
      assert township.latitute == "some latitute"
      assert township.longitude == "some longitude"
      assert township.title_bi == "some title_bi"
      assert township.title_en == "some title_en"
    end

    test "create_township/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_township(@invalid_attrs)
    end

    test "update_township/2 with valid data updates the township" do
      township = township_fixture()
      assert {:ok, township} = Contents.update_township(township, @update_attrs)
      assert %Township{} = township
      assert township.active == false
      assert township.latitute == "some updated latitute"
      assert township.longitude == "some updated longitude"
      assert township.title_bi == "some updated title_bi"
      assert township.title_en == "some updated title_en"
    end

    test "update_township/2 with invalid data returns error changeset" do
      township = township_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_township(township, @invalid_attrs)
      assert township == Contents.get_township!(township.id)
    end

    test "delete_township/1 deletes the township" do
      township = township_fixture()
      assert {:ok, %Township{}} = Contents.delete_township(township)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_township!(township.id) end
    end

    test "change_township/1 returns a township changeset" do
      township = township_fixture()
      assert %Ecto.Changeset{} = Contents.change_township(township)
    end
  end

  describe "divisions" do
    alias Boncoin.Contents.Division

    @valid_attrs %{active: true, latitute: "some latitute", longitude: "some longitude", title_bi: "some title_bi", title_en: "some title_en"}
    @update_attrs %{active: false, latitute: "some updated latitute", longitude: "some updated longitude", title_bi: "some updated title_bi", title_en: "some updated title_en"}
    @invalid_attrs %{active: nil, latitute: nil, longitude: nil, title_bi: nil, title_en: nil}

    def division_fixture(attrs \\ %{}) do
      {:ok, division} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contents.create_division()

      division
    end

    test "list_divisions/0 returns all divisions" do
      division = division_fixture()
      assert Contents.list_divisions() == [division]
    end

    test "get_division!/1 returns the division with given id" do
      division = division_fixture()
      assert Contents.get_division!(division.id) == division
    end

    test "create_division/1 with valid data creates a division" do
      assert {:ok, %Division{} = division} = Contents.create_division(@valid_attrs)
      assert division.active == true
      assert division.latitute == "some latitute"
      assert division.longitude == "some longitude"
      assert division.title_bi == "some title_bi"
      assert division.title_en == "some title_en"
    end

    test "create_division/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_division(@invalid_attrs)
    end

    test "update_division/2 with valid data updates the division" do
      division = division_fixture()
      assert {:ok, division} = Contents.update_division(division, @update_attrs)
      assert %Division{} = division
      assert division.active == false
      assert division.latitute == "some updated latitute"
      assert division.longitude == "some updated longitude"
      assert division.title_bi == "some updated title_bi"
      assert division.title_en == "some updated title_en"
    end

    test "update_division/2 with invalid data returns error changeset" do
      division = division_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_division(division, @invalid_attrs)
      assert division == Contents.get_division!(division.id)
    end

    test "delete_division/1 deletes the division" do
      division = division_fixture()
      assert {:ok, %Division{}} = Contents.delete_division(division)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_division!(division.id) end
    end

    test "change_division/1 returns a division changeset" do
      division = division_fixture()
      assert %Ecto.Changeset{} = Contents.change_division(division)
    end
  end

  describe "announces" do
    alias Boncoin.Contents.Announce

    @valid_attrs %{conditions: true, description: "some description", language: "some language", latitute: "some latitute", longitude: "some longitude", photo1: "some photo1", photo2: "some photo2", photo3: "some photo3", price: 120.5, status: "some status", title: "some title", validity_date: "2010-04-17 14:00:00.000000Z"}
    @update_attrs %{conditions: false, description: "some updated description", language: "some updated language", latitute: "some updated latitute", longitude: "some updated longitude", photo1: "some updated photo1", photo2: "some updated photo2", photo3: "some updated photo3", price: 456.7, status: "some updated status", title: "some updated title", validity_date: "2011-05-18 15:01:01.000000Z"}
    @invalid_attrs %{conditions: nil, description: nil, language: nil, latitute: nil, longitude: nil, photo1: nil, photo2: nil, photo3: nil, price: nil, status: nil, title: nil, validity_date: nil}

    def announce_fixture(attrs \\ %{}) do
      {:ok, announce} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Contents.create_announce()

      announce
    end

    test "list_announces/0 returns all announces" do
      announce = announce_fixture()
      assert Contents.list_announces() == [announce]
    end

    test "get_announce!/1 returns the announce with given id" do
      announce = announce_fixture()
      assert Contents.get_announce!(announce.id) == announce
    end

    test "create_announce/1 with valid data creates a announce" do
      assert {:ok, %Announce{} = announce} = Contents.create_announce(@valid_attrs)
      assert announce.conditions == true
      assert announce.description == "some description"
      assert announce.language == "some language"
      assert announce.latitute == "some latitute"
      assert announce.longitude == "some longitude"
      assert announce.photo1 == "some photo1"
      assert announce.photo2 == "some photo2"
      assert announce.photo3 == "some photo3"
      assert announce.price == 120.5
      assert announce.status == "some status"
      assert announce.title == "some title"
      assert announce.validity_date == DateTime.from_naive!(~N[2010-04-17 14:00:00.000000Z], "Etc/UTC")
    end

    test "create_announce/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_announce(@invalid_attrs)
    end

    test "update_announce/2 with valid data updates the announce" do
      announce = announce_fixture()
      assert {:ok, announce} = Contents.update_announce(announce, @update_attrs)
      assert %Announce{} = announce
      assert announce.conditions == false
      assert announce.description == "some updated description"
      assert announce.language == "some updated language"
      assert announce.latitute == "some updated latitute"
      assert announce.longitude == "some updated longitude"
      assert announce.photo1 == "some updated photo1"
      assert announce.photo2 == "some updated photo2"
      assert announce.photo3 == "some updated photo3"
      assert announce.price == 456.7
      assert announce.status == "some updated status"
      assert announce.title == "some updated title"
      assert announce.validity_date == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
    end

    test "update_announce/2 with invalid data returns error changeset" do
      announce = announce_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_announce(announce, @invalid_attrs)
      assert announce == Contents.get_announce!(announce.id)
    end

    test "delete_announce/1 deletes the announce" do
      announce = announce_fixture()
      assert {:ok, %Announce{}} = Contents.delete_announce(announce)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_announce!(announce.id) end
    end

    test "change_announce/1 returns a announce changeset" do
      announce = announce_fixture()
      assert %Ecto.Changeset{} = Contents.change_announce(announce)
    end
  end
end
