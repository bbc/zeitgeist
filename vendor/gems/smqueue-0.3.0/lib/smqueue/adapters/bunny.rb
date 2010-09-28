require 'bunny'
require 'pp'

module SMQueue
  class BunnyAdapter < Adapter

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

    # name
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
      if !self.connection
        self.connection = Bunny.new(
                                    :host => configuration.host,
                                    :port => configuration.port,
                                    :user => configuration.user,
                                    :password => configuration.password
                                    )
        connection.start
      end
    end

    def uuid
      `uuidgen`.chomp
    end

    # get message from queue
    def get(headers = {}, &block)
      message = nil
      connect
      SMQueue.dbg { "connecting to queue: #{configuration.name} #{configuration.kind.inspect}" }
      case configuration.kind
      when "fanout"
        SMQueue.dbg { "get from fanout" }
        exchange = connection.exchange(configuration.exchange, :type => :fanout, :auto_delete => true)
        # FIXME: queues binding to fanout exchanges must have unique names - need more than this
        q = connection.queue(configuration.name + ".#{uuid}", :auto_delete => true)
        q.bind(exchange)
      when "queue"
        SMQueue.dbg { "get from queue" }
        q = connection.queue(configuration.name)
      else
        raise Exception, "Unknown queue type: #{configuration.kind}"
      end
      if block
        SMQueue.dbg { "entering loop get" }
        q.subscribe do |msg|
          SMQueue.dbg { [:get, :loop, :msg, msg].inspect }
          message = SMQueue::Message.new(:body => msg[:payload])
          block.call(message)
        end
      else
        SMQueue.dbg { "singleshot get" }
        while msg.nil?
          msg = q.pop
          message = SMQueue::Message.new(:body => msg[:payload])
          sleep 0.1
        end
      end
      SMQueue.dbg { [:smqueue, :get, headers].inspect }
      message
    end

    # put a message on the queue
    def put(body, headers = { })
      body, headers = normalize_message(body, headers)
      SMQueue.dbg { [:smqueue, :put, body, headers].inspect }
      self.connect
      SMQueue.dbg { [:smqueue, :put, :publishing].inspect }
      SMQueue.dbg { [:smqueue, :creating, configuration.kind].inspect }
      #q = connection.send(configuration.exchange, configuration.name)
      channel = case configuration.kind
          when "fanout"
            SMQueue.dbg { "put to fanout" }
            connection.exchange(configuration.exchange, :type => :fanout)
          when "queue"
            SMQueue.dbg { "put to queue" }
            connection.queue(configuration.name)
          else
            raise Exception, "Unknown exchange type: #{configuration.kind}"
          end
      SMQueue.dbg { [:smqueue, :put, :after_creation, channel].pretty_inspect }
      rv = channel.publish(body)
      SMQueue.dbg { [:smqueue, :put, :after_put, rv].pretty_inspect }
    end
  end
end
