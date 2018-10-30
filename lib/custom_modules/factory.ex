defmodule Boncoin.Factory do
  use ExMachina.Ecto, repo: Boncoin.Repo
  alias Boncoin.Members.{User, Conversation}
  alias Boncoin.Contents.{Family, Category, Township, Division, Announce, Image, TrafficKpi}

  def admin_user_factory do
    %User{
      phone_number: "09000000003",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: "ADMIN",
      language: "en",
      member_psw: "e",
      bot_provider: "viber",
      bot_active: true,
      bot_id: "e",
      nickname: "Mr admin",
    }
  end

  def member_user_factory do
    %User{
      phone_number: "09000000002",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: "MEMBER",
      language: "en",
      member_psw: "e",
      bot_provider: "viber",
      bot_active: true,
      bot_id: "12345671",
      nickname: "Mr member",
    }
  end

  # def guest_user_factory do
  #   %User{
  #     phone_number: "09000000000",
  #     email: sequence(:email, &"email-#{&1}@example.com"),
  #     role: "GUEST",
  #     language: "en",
  #     member_psw: "e",
  #     bot_provider: "viber",
  #     bot_active: true,
  #     bot_id: "e",
  #     nickname: "Mr guest",
  #   }
  # end

  def user_factory do
    %User{
      phone_number: "09000000000",
      email: sequence(:email, &"email-#{&1}@example.com"),
      role: sequence(:role, ["ADMIN", "MEMBER"]),
      language: "en",
      member_psw: "e",
      bot_provider: "viber",
      bot_active: true,
      bot_id: "e",
      nickname: "Mr unknown",
    }
  end

  def conversation_factory do
    %Conversation {
      bot_provider: "viber",
      psid: "some psid",
      scope: "some scope"
    }
  end

  def family_factory do
    %Family{
      title_en: "Technology",
      title_my: "ရန်ကုံန်",
      rank: 1,
      active: true,
      icon: "mobile-alt",
      icon_type: "fa"
    }
  end

  def category_factory do
    category = insert(:family)
    %Category{
      title_en: "Technology",
      title_my: "ရန်ကုံန်",
      family_id: category.id,
      rank: 1,
      active: true,
      icon: "mobile-alt",
      icon_type: "fa"
    }
  end

  def division_factory do
    %Division{
      title_en: "Yangon",
      title_my: "ရန်ကုံန်",
      active: true
    }
  end

  def township_factory do
    division = insert(:division)
    %Township{
      title_en: "Yangon",
      title_my: "ရန်ကုံန်",
      division_id: division.id,
      active: true
    }
  end

  def announce_factory do
    user = insert(:member_user)
    division = insert(:division, %{active: true})
    township = insert(:township, %{active: true, division_id: division.id})
    family = insert(:family, %{active: true})
    category = insert(:category, %{active: true, family_id: family.id})
    %Announce{
      title: "an offer title",
      price: 10.0,
      description: "an offer description",
      currency: "USD",
      status: "ONLINE",
      township_id: township.id,
      category_id: category.id,
      user_id: user.id,
      conditions: true,
      language: "en",
      parution_date: Timex.now()
    }
  end

end
