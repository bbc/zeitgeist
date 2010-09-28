#!/usr/bin/env ruby
# -*- mode: ruby; -*-
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require LoadPath.app_path("db")
require LoadPath.model_path("queries")
require 'resolve_link'
require 'pp'

include Query
include ResolveLink

puts "starting update_metadata"

loop do
  date = [Date.today - 1, Date.today]
  links = total_links_by_url(date, :threshold => 1, :limit => 1000, :where => "metadata is null")
  links.each do |link|
    begin
      p [:link, link]
      if link.url !~ %r{^http://.*bbc.co.uk}
        p [:skipping]
        next
      end
      #pp [url.url, url.total]
      link = Link.first(:url => link.url)
      # pp [link.url, link.metadata]
      if link.metadata.nil?
        p [:creating_metadata, link.url]
        link.update_metadata
        link.save
      else
        #p [:skipping, link.url]
      end
    rescue => e
      p [:error, e, link.url]
    end
  end
  sleep 60
end
