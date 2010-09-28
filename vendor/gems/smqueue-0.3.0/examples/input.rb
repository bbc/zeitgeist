require 'smqueue'
require 'pp'

script_path = File.dirname(__FILE__)
configuration = YAML::load(File.read(File.join(script_path, "config", "example_config.yml")))

if ARGV.size > 0
  queue_name = ARGV[0].to_sym
else
  queue_name = :input
end
# pp [queue_name, configuration[queue_name]]

input_queue = SMQueue.new(:configuration => configuration[queue_name])

# You can't mix these up with the AMQPAdaptor (not until I figure out how to unsubscribe using AMQP)
# p input_queue.get

input_queue.get do |msg|
  pp msg
  puts "-" * 40
  puts msg.body
  puts "-" * 40
end
