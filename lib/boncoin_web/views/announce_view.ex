defmodule BoncoinWeb.AnnounceView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def image_url(image, type) do
    Boncoin.AnnounceImage.url({image.file, image}, type)
  end

  def show_date(datetime, language) do
    day = datetime.day
    month = datetime.month
    year = datetime.year
    {hour, label} = Timex.Time.to_12hour_clock(datetime.hour) # {2, :pm}
    minute = datetime.minute
    day_now = Timex.now()
    duration = Timex.diff(day_now, datetime, :days)
    case duration do
      0 ->
        # Less than 24 hours ago
        case day == day_now do
          true ->
            # Same day
            gettext("today, %{hour}:%{minute} %{label}", hour: hour, minute: minute, label: label) #Today, 2:30 PM
          false ->
            # Yesterday
            gettext("yesterday, %{hour}:%{minute} %{label}", hour: hour, minute: minute, label: label) #Yesterday, 2:30 PM
        end
      1 ->
        # Less than 48 hours ago
        gettext("yesterday, %{hour}:%{minute} %{label}", hour: hour, minute: minute, label: label) #Yesterday, 2:30 PM
      _ ->
        # Another day
        "#{year}/#{month}/#{day}" #1018/10/02
    end
  end

  def show_price(price, currency) do
    "#{Kernel.round(price)} #{currency}"
  end

  def show_location(township, language) do
    case language do
      "en" -> "#{township.division.title_en}, #{township.title_en}"
    end
  end

end
