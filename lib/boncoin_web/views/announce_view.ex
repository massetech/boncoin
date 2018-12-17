defmodule BoncoinWeb.AnnounceView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def render("offer_api.json", %{results: results}) do
    %{results: results}
  end

  def check_and_add_pub(conn, i) do
    # Put a big pub every 20 offers
    if (rem(i+1, 20) == 0) && i != 0 do
      render BoncoinWeb.PubView, "_display_pub_big.html", conn: conn
    else
      if (rem(i+1, 5) == 0) && i != 0 do
        render BoncoinWeb.PubView, "_display_pub_small.html", conn: conn
      end
    end
  end

  def image_url(image, type) do
    case image do
      nil -> "default_url" # We allow nil image for test only
      _ -> Boncoin.AnnounceImage.url({image.file, image}, type)
    end
  end

  def btn_status(status) do
    case status do
      "PENDING" -> "btn btn-primary btn-sm"
      "ONLINE" -> "btn btn-success btn-sm"
      "REFUSED" -> "btn btn-danger btn-sm"
      "OUTDATED" -> "btn btn-warning btn-sm"
      "CLOSED" -> "btn btn-info btn-sm"
    end
  end

  def show_date(announce) do
    day_now = Timex.now()
    datetime = if announce.parution_date != nil, do: announce.parution_date, else: announce.inserted_at
    # year = datetime.year
    # month = datetime.month
    # minute = datetime.minute
    day = datetime.day
    duration_day = Timex.diff(day_now, datetime, :days)
    duration_hour = Timex.diff(day_now, datetime, :hours)
    duration_min = Timex.diff(day_now, datetime, :minutes)
    cond do
      duration_min < 60 -> ngettext("one minute ago", "%{count} minutes ago", duration_min)
      duration_hour < 24 && day == day_now.day -> ngettext("one hour ago", "%{count} hours ago", duration_hour)
      duration_day == 1 -> gettext("yesterday")
      true -> ngettext("one day ago", "%{count} days ago", duration_day)
    end
  end

  def show_price(price, "USD") do
    case Gettext.get_locale() do
      "en" -> "#{price} USD"
      "my" -> "#{price} USD"
      "dz" -> "#{Rabbit.uni2zg(price)} USD"
    end
  end
  def show_price(price, "Kyats") do
    case Gettext.get_locale() do
      "en" -> "#{price} Kyats"
      "my" -> "#{price} ကျပ်"
      "dz" -> "#{Rabbit.uni2zg(price)} #{Rabbit.uni2zg("ကျပ်")}"
    end
  end

  def show_sell_mode(sell_mode) do
    case sell_mode do
      "SELL" -> "fa-dollar-sign"
      "RENT" -> "fa-clock"
      "GIVE" -> "fa-gift"
    end
  end

  # def announce_sell_mode(sell_mode) do
  #   case sell_mode do
  #     "sell" -> "fa-dollar-sign"
  #     "rent" -> "fa-clock"
  #     "give" -> "fa-gift"
  #   end
  # end

  def explain_sell_mode(sell_mode) do
    case sell_mode do
      "SELL" -> gettext("The owner is selling the product")
      "RENT" -> gettext("The owner is renting the product")
      "GIVE" -> gettext("The owner gives the product, you can propose your price")
    end
  end

  # def show_location(township, language) do
  #   uni = "#{township.title_my}" #{township.division.title_my},
  #   case language do
  #     "en" -> "#{township.title_en}"
  #     "my" -> uni
  #     "en" -> Rabbit.uni2zg(uni)
  #   end
  # end

end
