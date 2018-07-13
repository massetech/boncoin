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

Repo.insert! %User{email: "bitocreator@gmail.com", role: "SUPER"}

Repo.insert! %Division{title_en: "Yangon", title_bi: "ရန်ကုံန်", active: true}
Repo.insert! %Division{title_en: "Dawei", title_bi: "ဒာဝေး", active: true}
Repo.insert! %Division{title_en: "Mandaley", title_bi: "မန်တာလေး", active: true}

Repo.insert! %Family{title_en: "Property", title_bi: "ရန်ကုံန်", active: true, icon: "bicycle"}
Repo.insert! %Family{title_en: "Vehicule", title_bi: "ရန်ကုံန်", active: true, icon: "bicycle"}
Repo.insert! %Family{title_en: "Technology", title_bi: "ရန်ကုံန်", active: true, icon: "bicycle"}
Repo.insert! %Family{title_en: "House", title_bi: "ရန်ကုံန်", active: true, icon: "bicycle"}

for division <- Repo.all(Division) do
  for i <- 1..3 do
    Repo.insert! %Township{division_id: division.id, title_en: "Town #{i}", title_bi: "မျိုး #{i}", active: true}
  end
end

for family <- Repo.all(Family) do
  for i <- 1..3 do
    Repo.insert! %Category{family_id: family.id, title_en: "Category #{i}", title_bi: "ပျစ်စစ် #{i}", active: true, icon: "home"}
  end
end
