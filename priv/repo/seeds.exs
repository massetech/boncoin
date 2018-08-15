alias Boncoin.Repo
alias Boncoin.Contents.{Family, Category, Division, Township, Announce}
alias Boncoin.Members.{User}
alias Boncoin.Members

Repo.delete_all(Family)
Repo.delete_all(Category)
Repo.delete_all(Division)
Repo.delete_all(Township)
Repo.delete_all(Announce)
Repo.delete_all(User)

Repo.insert! %User{email: "", role: "GUEST", phone_number: "", language: "en", member_psw: "", viber_active: false, viber_id: "", nickname: "Guest"}
Repo.insert! %User{email: "bitocreator@gmail.com", role: "SUPER", phone_number: "09000000000", language: "en", member_psw: "fouesnant", viber_active: true, viber_id: "hPAtCbK9yIaDQumAoQ50sQ==", nickname: "Thib"}

Repo.insert! %Division{title_en: "Yangon", title_my: "ရန်ကုံန်", active: true}
Repo.insert! %Division{title_en: "Dawei", title_my: "ဒာဝေး", active: true}
Repo.insert! %Division{title_en: "Mandaley", title_my: "မန်တာလေး", active: true}

Repo.insert! %Family{title_en: "Technology", title_my: "ရန်ကုံန်", active: true, icon: "mobile-alt"}
Repo.insert! %Family{title_en: "Vehicule", title_my: "ရန်ကုံန်", active: true, icon: "car"}
Repo.insert! %Family{title_en: "Household", title_my: "ရန်ကုံန်", active: true, icon: "home"}
Repo.insert! %Family{title_en: "Culture", title_my: "ရန်ကုံန်", active: true, icon: "music"}
Repo.insert! %Family{title_en: "Professional", title_my: "ရန်ကုံန်", active: true, icon: "briefcase"}


for division <- Repo.all(Division) do
  for i <- 1..3 do
    Repo.insert! %Township{division_id: division.id, title_en: "Town #{i}", title_my: "မျိုး #{i}", active: true}
  end
end

for family <- Repo.all(Family) do
  for i <- 1..3 do
    Repo.insert! %Category{family_id: family.id, title_en: "Category #{i}", title_my: "ပျစ်စစ် #{i}", active: true, icon: "home"}
  end
end

announce_params = %{"user_id" => 2, "language" => "en", "category_id" => 1, "township_id" => 1, "title" => "my bike",
  "price" => 10.0, "description" => "its a nice bike dude", "currency" => "USD",
  "image_file_1" => "", "image_file_2" => "", "image_file_3" => ""}
|> Boncoin.Contents.create_announce()
