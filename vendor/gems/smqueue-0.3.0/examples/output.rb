require 'smqueue'
require 'pp'

script_path = File.dirname(__FILE__)
configuration = YAML::load(File.read(File.join(script_path, "config", "example_config.yml")))

input_name = (ARGV[0] || :readline).to_sym
output_name = (ARGV[1] || :stdio).to_sym

input_queue = SMQueue.new(:configuration => configuration[input_name])
output_queue = SMQueue.new(:configuration => configuration[output_name])

input_queue.get do |msg|
  output_queue.put msg.body
end
