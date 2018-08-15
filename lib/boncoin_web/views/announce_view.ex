defmodule BoncoinWeb.AnnounceView do
  use BoncoinWeb, :view
  alias BoncoinWeb.LayoutView

  def image_url(image, type) do
    Boncoin.AnnounceImage.url({image.file, image}, type)
  end

  def btn_status(status) do
    case status do
      "PENDING" -> "<div class='btn btn-primary btn-sm'>PENDING</div>" |> raw
      "ONLINE" -> "<div class='btn btn-success btn-sm'>ONLINE</div>" |> raw
      "REFUSED" -> "<div class='btn btn-danger btn-sm'>REFUSED</div>" |> raw
      "OUTDATED" -> "<div class='btn btn-warning btn-sm'>OUTDATED</div>" |> raw
      "CLOSED" -> "<div class='btn btn-info btn-sm'>CLOSED</div>" |> raw
    end
  end

  def show_date(announce, language) do
    IO.puts("hey")
    IO.inspect(announce)
    if announce.parution_date != nil, do: datetime = announce.parution_date, else: datetime = announce.inserted_at
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
        case day == day_now.day do
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
