#!/usr/bin/env ruby
require 'yaml'
require 'pp'
require 'lib/quotes'
include Quotes

queues = Hash.new { |h, k| h[k] = { :inputs => [], :outputs => [] }}
process_list = []


files = Dir["smq_config/*.yml"]
files.each do |file|
  data = YAML::load(File.read(file))
  if processes = data[:processes]
    processes.each do |process|
      if args = process[:args]
        process_list << process[:name]
        if input = args[:input]
          queues[input][:inputs] << process[:name]
        end
        if output = args[:output]
          queues[output][:outputs] << process[:name]
        end
      end
    end
  end
end

# pp queues

# dot output
puts "digraph pipeline {"

process_list.each do |process|
  puts "p_#{process}[shape=ellipse,label=#{qq process}];"
end

queues.each do |key, q|
  puts "q_#{key}[shape=rectangle,label=#{qq key}];"
end

# queue outputs == processor inputs
queues.each do |key, q|
  if inputs = q[:inputs]
    inputs.each do |input|
      puts "q_#{key} -> p_#{input};"
    end
  end
  if outputs = q[:outputs]
    outputs.each do |output|
      puts "p_#{output} -> q_#{key};"
    end
  end
end

puts "}"
