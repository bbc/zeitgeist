require 'time'

module DateFormat
  extend self

  ## ordinal_suffix(number) - returns "st" for 1, "nd" for 2, etc.
  def ordinal_suffix(number)
    case (number % 10)
    when 1
      "st"
    when 2
      "nd"
    when 3
      "rd"
    else
      "th"
    end
  end

  ## format_date(date) - May 1st
  def format_date(date)
    "#{date.strftime("%B")} #{date.day}#{ordinal_suffix(date.day)}"
  end

  ## format_date(date) - 3:21 PM
  def format_time(time)
    time.strftime("%I:%M %P").gsub(/^0/, '')
  end

  ## format_datetime(datetime) - 1:29 PM May 4th
  def format_datetime(datetime)
    "#{format_time(datetime)} #{format_date(datetime)}"
  end

  def seconds(n)
    n
  end

  def minutes(n)
    seconds(n * 60)
  end

  def hours(n)
    minutes(n * 60)
  end

  ## round_down_to_hour(time)
  def round_down_to_hour(time)
    time - minutes(time.min) - seconds(time.sec)
  end

  ## round_up_to_hour(time)
  def round_up_to_hour(time)
    round_down_to_hour(time + hours(1))
  end

end
