defmodule BoncoinWeb.AnnounceView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def render("offer_api.json", %{results: results}) do
    %{results: results}
  end

  def image_url(image, type) do
    case image do
      nil -> "default_url" # We allow nil image for test only
      _ -> Boncoin.AnnounceImage.url({image.file, image}, type)
    end
  end

  def btn_status(status) do
    case status do
      "PENDING" -> "<div class='btn btn-secondary btn-sm'>PENDING</div>" |> raw
      "ONLINE" -> "<div class='btn btn-success btn-sm'>ONLINE</div>" |> raw
      "REFUSED" -> "<div class='btn btn-danger btn-sm'>REFUSED</div>" |> raw
      "OUTDATED" -> "<div class='btn btn-warning btn-sm'>OUTDATED</div>" |> raw
      "CLOSED" -> "<div class='btn btn-info btn-sm'>CLOSED</div>" |> raw
    end
  end

  def show_date(announce, language) do
    day_now = Timex.now()
    datetime = if announce.parution_date != nil, do: announce.parution_date, else: announce.inserted_at
    year = datetime.year
    month = datetime.month
    day = datetime.day
    minute = datetime.minute
    # {hour, label} = Timex.Time.to_12hour_clock(datetime.hour) # {2, :pm}
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

  def show_price(price, currency) do
    "#{Kernel.round(price)} #{currency}"
  end

  def show_sell_mode(sell_mode) do
    case sell_mode do
      "sell" -> "fa-dollar-sign"
      "rent" -> "fa-clock"
      "give" -> "fa-gift"
    end
  end

  def announce_sell_mode(sell_mode) do
    case sell_mode do
      "sell" -> "fa-dollar-sign"
      "rent" -> "fa-clock"
      "give" -> "fa-gift"
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
