require 'thread'
require 'thin'
require 'doodle/datatypes'

module Thin
  class Server
    protected
    def setup_signals
      trap('QUIT') { stop }  unless Thin.win?
      trap('INT')  { exit }
      trap('TERM') { exit }
    end
  end
end

module SMQueue
  class MW
    def initialize(app)
      @app = app
    end
    def call(env)
      pp [:ENV, env]
      response = @app.call(env)
      pp [:RESPONSE, response]
      response
    end
  end

  class RackAdapter
    attr_accessor :thread_queue
    def initialize(queue, &block)
      @thread_queue = queue
    end
    def call(env)
      p self.class
      env = env.dup
      req = Rack::Request.new(env)
      if req.form_data? && req.post?
        body = req.params
      else
        body = env['rack.input'].read.to_s
      end
      msg = SMQueue::Message.new(:headers => env, :body => body.to_yaml)
      @thread_queue.enq(msg)
      [201, { "Content-Length" => "0", "Content-Type" => "text/plain" }, ""]
    end
  end

  class HTTPServerAdapter < Adapter
    QUEUES = { }

    class Configuration < AdapterConfiguration
      def initialize(*args, &block)
        #p [self.class, args]
        super
      end
      doodle do
        uri :uri
      end
    end

    attr_accessor :thread

    doc "in memory threadsafe queue"
    has :thread_queue do
      doc "internal ref to thread-safe Queue"
      init { Queue.new }
    end

    def initialize(*args, &block)
      super
      this = self
      configuration = self.configuration
      self.thread = Thread.start(this, configuration) {|this, configuration|
        Thin::Server.start('0.0.0.0', configuration.uri.port) do
          use Rack::CommonLogger
          use Rack::ShowExceptions
          map configuration.uri.path do
            # use MW
            use Rack::Lint
            run RackAdapter.new(this.thread_queue)
          end
        end
      }
    end

    def put(body, headers = { }, &block)
      body, headers = normalize_message(body, headers)
      # RestClient?
      #p [:tput, args]
      # thread_queue.enq(*args)
    end

    def get(*args, &block)
      p [:tget]
      loop do
        p [:tget, :loop]
        msg = thread_queue.deq
        yield(msg)
      end
    end

    def close
      self.thread.kill
    end
  end
end

