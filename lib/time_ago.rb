
require 'date'
class Time
  def to_datetime
    # Convert seconds + microseconds into a fractional number of seconds
    seconds = sec + Rational(usec, 10**6)

    # Convert a UTC offset measured in minutes to one measured in a
    # fraction of a day.
    offset = Rational(utc_offset, 60 * 60 * 24)
    DateTime.new(year, month, day, hour, min, seconds, offset)
  end
end

module TimeAgo
  extend self
  def time_ago(time, options = {})
    if time.nil?
      return "(unknown)"
    end
    # ensure we have a time
    time = time.to_time
    start_date = options.delete(:start_date) || Time.new
    date_format = options.delete(:date_format) || "%Y-%m-%d"
    delta_minutes = (start_date.to_i - time.to_i).floor / 60
    if delta_minutes.abs <= (8724*60)
      distance = distance_of_time_in_words(delta_minutes)
      if delta_minutes < 0
        "#{distance} from now"
      else
        "#{distance} ago"
      end
    else
      "on #{DateTime.now.strftime(date_format)}"
    end
  end
  def pluralize(minutes)
    case minutes
    when 1
      "one minute"
    else
      "#{minutes} minutes"
    end
  end
  def distance_of_time_in_words(minutes)
    case
    when minutes < 1
      "less than a minute"
    when minutes < 50
      pluralize(minutes)
    when minutes < 90
      "about one hour"
    when minutes < 1080
      "#{(minutes / 60).round} hours"
    when minutes < 1440
      # "one day"
      "#{(minutes / 60).round} hours"
    when minutes < 2880
      # "about one day"
      "#{(minutes / 60).round} hours"
    when minutes < 1440 * 7
      "#{(minutes / 1440).round} days"
    when minutes < 1440 * 8
      "a week"
    when minutes < 1440 * 11
      # < 11 days
      "> week"
    when minutes < 1440 * 14
      # < 14 days
      "2 weeks"
    else
      "> 2 weeks"
    end
  end
end
