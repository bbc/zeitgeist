require "doodle"
require "doodle/json"
require 'uuid'

class QueueConfig < Doodle
  BASE_DIR   = File.expand_path(File.join(File.dirname(__FILE__), ".."))
  SCRIPT_DIR = File.join(BASE_DIR, "scripts")
  doodle do
    string :name
    string :request_id do
      default { uuid }
    end
    has :env, :kind => Hash do
      default do
        { }
      end
    end
    string :input, :default => "input"
    string :output, :default => "output"
    string :input_queue_name, :default => nil
    string :output_queue_name, :default => nil
    string :script, :default => "filter"
    string :config, :default => "#{BASE_DIR}/config/mq.yml"
    has :params, :kind => Hash, :default => { } # maybe make this required
    string :dir, :default => SCRIPT_DIR
    string :pid_directory, :default => "/tmp"
    string :log_directory, :default => "/tmp"
  end
end
