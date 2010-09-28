require 'mq'
require 'pp'

Thread.abort_on_exception = true

module SMQueue
  class AMQPAdapter < Adapter
    module EventMachine
      def self.safe_run(background = nil, &block)
        if ::EM::reactor_running?
          # Attention: here we loose the ability to catch
          # immediate connection errors.
          ::EM::next_tick(&block)
          sleep unless background # this blocks the thread as it was inside a reactor
        else
          if background
            @@em_reactor_thread = Thread.new do
              ::EM::run(&block)
            end
          else
            ::EM::run(&block)
          end
        end
      end
    end

    class Configuration < AdapterConfiguration
      has :host, :kind => String, :default => "localhost" do
        doc <<-EDOC
          The host that runs the broker you want to connect to.
        EDOC
      end
      has :port, :kind => Integer, :default => 5672 do
        doc <<-EDOC
          The port that your message broker is accepting connections on.
        EDOC
      end
      has :name, :kind => String, :default => "", :doc => "name of queue to connect to"
      has :kind, :kind => String, :default => "queue", :doc => "'queue' or 'fanout'" do
        values = %w[queue fanout topic]
        from Symbol do |s|
          s.to_s
        end
        must "be one of #{values.join(', ')}" do |s|
          values.include?(s)
        end
      end
      has :exchange, :kind => String, :default => "direct"
      has :logfile, :default => STDERR do
        doc <<-EDOC
          Where should we log to. Default is STDERR.
        EDOC
      end
      has :logger, :default => nil do
        doc <<-EDOC
          A logger that's to log with. If this is left out of the options a
          new Logger is built that talks to the logfile.
        EDOC
      end #'
      has :user, :default => "guest"
      has :password, :default => "guest"
    end
    has :connection, :default => nil

    def name
      configuration.name
    end

    # handle an error
    def handle_error(exception_class, error_message, caller)
      #configuration.logger.warn error_message
      raise exception_class, error_message, caller
    end

    # connect to message broker
    def connect(*args, &block)
      AMQP.start(
                 :host => configuration.host,
                 #:port => configuration.port,
                 :user => configuration.user,
                 :password => configuration.password
                 )
      self.connection ||= MQ.new
    end

    # get message from queue
    def get(headers = {}, &block)
      message = nil
      EventMachine.safe_run do
        connect
        SMQueue.dbg { "connecting to queue: #{configuration.name}" }
        q = case configuration.kind
            when "fanout"
              # connection.queue(configuration.name).bind(connection.exchange(configuration.exchange, :type => :fanout))
              connection.queue(configuration.name).bind(connection.fanout(configuration.exchange))
            when "queue"
              connection.queue(configuration.name)
            else
              raise Exception, "Unknown queue type: #{configuration.kind}"
            end
        if block
          SMQueue.dbg { "entering loop get" }
          q.subscribe do |msg|
            SMQueue.dbg { [:get, :loop, :msg, msg].inspect }
            message = SMQueue::Message.new(:body => msg)
            block.call(message)
          end
        else
          SMQueue.dbg { "singleshot get" }
          q.subscribe do |msg|
            message = SMQueue::Message.new(:body => msg)
            SMQueue.dbg { [:get, :singleshot, :msg, msg].inspect }
            SMQueue.dbg { [:get, :unsubscribing].inspect }
            q.unsubscribe(:nowait => false) do
              SMQueue.dbg { [:get, :unsubscribed ] }
            end
            ::EM.stop
          end
        end
        SMQueue.dbg { [:smqueue, :get, headers].inspect }
      end
      message
    end

    # put a message on the queue
    def put(body, headers = { })
      body, headers = normalize_message(body, headers)
      SMQueue.dbg { [:smqueue, :put, body, headers].inspect }
      EventMachine.safe_run(true) do
        SMQueue.dbg { [:smqueue, :put, :connecting].inspect }
        self.connect
        SMQueue.dbg { [:smqueue, :put, :publishing].inspect }
        SMQueue.dbg { [:smqueue, :creating, configuration.kind].inspect }
        #q = connection.send(configuration.exchange, configuration.name)
        q = case configuration.kind
            when "fanout"
              connection.fanout(configuration.exchange)
            when "queue"
              connection.queue(configuration.name)
            else
              raise Exception, "Unknown exchange type: #{configuration.kind}"
            end
        SMQueue.dbg { [:smqueue, :put, :after_creation, q].pretty_inspect }
        rv = q.publish(body)
        SMQueue.dbg { [:smqueue, :put, :after_put, rv].pretty_inspect }
      end
      SMQueue.dbg { [:num_threads, Thread.list.size].inspect }
    end
  end
  AmqpAdapter = AMQPAdapter
end
