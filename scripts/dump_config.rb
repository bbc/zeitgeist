#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/load_paths')

require 'yaml'
require 'pp'
require 'config'

key = ARGV.shift
sym_key = key.to_sym

ARGV.each do |file|
  # STDERR.puts file
  data = ConfigHelper.load_config(file)
  if data.respond_to?(:key?)
    begin
      if cfg = data[key]
        p [:file, key, file]
        p cfg
      end
      if cfg = data[sym_key]
        p [file, sym_key]
        p cfg
      end
    rescue => e
      p [:exception, e, data]
    end
  end
end

# data = YAML.load(File.read(ARGV[0]))
# pp data
