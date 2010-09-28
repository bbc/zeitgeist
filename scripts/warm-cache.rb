#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require 'code_timer'
require 'logger'
require 'json'
require 'yaml'

LoadPath.require(:app, "db")
LoadPath.model("queries")

class LinkRow
  attr_accessor :first_tweeted_at
  attr_accessor :media_type
  attr_accessor :metadata
  attr_accessor :section
  attr_accessor :total
  attr_accessor :url

  def initialize(params)
    fta = params["first_tweeted_at"]
    @first_tweeted_at =
      case fta
      when String
        Time.parse(fta)
      when DateTime
        fta.to_time
      when Time
        fta
      when NilClass
        fta
      else
        raise ArgumentError, "Need a Time for first_tweeted_at (got a #{fta.class})"
      end
    @media_type       = params["media_type"]
    @metadata         = params["metadata"]
    @section          = params["section"]
    @total            = params["total"]
    @url              = params["url"]
  end
end

def logger
  @logger ||= Logger.new(STDOUT)
end

def group_results(results, date, attribute, &block)
  groups = results.group_by(&block).map{ |key, results| [key, results.inject(0){ |total, row| total + row.total }] }.sort_by{ |row| -row[1]}
  groups.inject({ }) { |hash, (group, count)|
    hash[group] = Query.total_links_by_url(date, :where => ["#{attribute} = '#{group}'"])
    hash
  }
end

def results_by_date(date)
  options = { }
  results = Query.total_links_by_url(date, options)
  results_by_section = group_results(results, date, :section) { |link| link.section }
  results_by_media_type = group_results(results, date, :media_type) { |link| link.media_type }
  { :total => results, :by_section => results_by_section, :by_media_type => results_by_media_type }
end

def results_by_week
  date = [Date.today - 6, Date.today]
  results_by_date(date)
end

def results_by_day
  date = [Date.today - 1, Date.today + 1]
  results_by_date(date)
end

def all_results
  { :by_day => results_by_day, :by_week => results_by_week }
end

# write to public
# change url to be /by_week/media_type/video, etc.
# /by_week/section/Science%20and%20Entertainment, etc.

class Struct
  def to_hash
    Hash[*self.class.members.zip(self.to_a).flatten(1)]
  end
end

if __FILE__ == $0
  results = []
  CodeTimer.timer("all_results") {
    results = all_results
  }
  # this works but is reet dirty
  # puts results[:by_day][:total].to_yaml.gsub(/\!ruby\/struct:/, '')

  results.keys.each do |key1|
    results[key1].keys.each do |key2|
      File.open("var/#{key1}-#{key2}.yml", "w") do |file|
        file.puts results[key1][key2].map{ |x| LinkRow.new(x.to_hash)}.to_yaml
      end
    end
  end

end

