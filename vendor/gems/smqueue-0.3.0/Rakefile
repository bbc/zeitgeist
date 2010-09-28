# Rakefile for smqueue
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name              = "smqueue"
    s.version           = "0.3.0"
    s.summary           = "Simple Message Queue"
    s.email             = "seanohalpin@gmail.com"
    s.homepage          = 'http://github.com/seanohalpin/smqueue'
    s.description       = "Implements a simple protocol for using message queues, with adapters for STOMP (ActiveMQ), AMQP, XMPP PubSub, HTTP, Spread and stdio (for testing)."
    s.authors           = ["Sean O'Halpin", "Chris O'Sullivan", "Craig Webster"]
    s.files             =
      [
       "History.txt",
       "Manifest.txt",
       "README.txt",
       "Rakefile",
       "examples/input.rb",
       "examples/output.rb",
       "examples/config/example_config.yml",
       "lib/rstomp.rb",
       "lib/smqueue.rb",
       "smqueue.gemspec",
       "test/helper.rb",
       "test/test_rstomp_connection.rb",
      ] + Dir["lib/smqueue/adapters/*.rb"]
    s.test_files        = ["test/test_rstomp_connection.rb"]
    s.add_dependency("doodle", [">= 0.1.9"])
    s.rubyforge_project = 'smqueue'
    s.extra_rdoc_files  = %w[
History.txt
Manifest.txt
README.rdoc
]
    s.rdoc_options      = ["--charset=UTF-8 --line-numbers", "--inline-source", "--title", "Doodle", "--main", "README.rdoc"]
    s.add_development_dependency('jeweler')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError => e
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end
