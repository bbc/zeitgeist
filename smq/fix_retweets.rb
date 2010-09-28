#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require LoadPath.app_path("db")
require 'pp'
require 'date_format'

def df(range)
  DateFormat.format_date(range.first) + "-" + DateFormat.format_date(range.last)
end

# do the last 3 days only
while true
  0.upto(2) do |i|
    from = i
    to   = i - 1
    range = ((Date.today - i)..(Date.today - to))
    p [:range, df(range)]
    tweets = Tweet.all(:created_at => range)
    p [:count, df(range), tweets.size]
    count = 0
    tweets.each do |tweet|
      begin
        #p [:updating, tweet.twid]
        tweet.touch
        count += 1
        if count % 100 == 0
          p [:count, df(range), count]
        end
      rescue => e
        p [:error, e.to_s[0..50], tweet.twid]
      ensure
        sleep 0.2
      end
    end
  end
  puts "sleeping"
  sleep 60
end
