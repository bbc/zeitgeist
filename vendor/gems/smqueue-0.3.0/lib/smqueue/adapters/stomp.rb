require 'rstomp'
module SMQueue
  class StompAdapter < Adapter
    class Configuration < AdapterConfiguration
      has :host, :kind => String, :default => "" do
        doc <<-EDOC
          The host that runs the broker you want to connect to.
        EDOC
      end
      has :port, :kind => Integer, :default => 61613 do
        doc <<-EDOC
          The host that your broker is talking STOMP on.

          The default port for STOMP is 61613.
        EDOC
      end
      # TODO: document

      has :secondary_host, :kind => String, :default => ""
      has :secondary_port, :kind => Integer, :default => 61613
      # TODO: Find out how this is used
      has :name, :kind => String, :default => ""
      has :user, :kind => String, :default => "" do
        doc <<-EDOC
          The user to attempt to authenticate at the broker with.

          If your broker isn't setup for authentication just leave this blank.
        EDOC
      end
      has :password, :kind => String, :default => "" do
        doc <<-EDOC
          The password to attempt to authenticate at the broker with.

          If your broker isn't setup for authentication just leave this blank.
        EDOC
      end
      # TODO: I think that reliable means the connection will be reconnected
      # after a disconnect. Find out if that's the case and document it.
      has :reliable, :default => false
      # TODO: document this
      # TODO: I think that persistent means that the message will be stored by
      # the broker on a PUT before it sends an ACK.
      has :persistent, :default => true
      has :reconnect_delay, :default => 5 do
        doc <<-EDOC
          How long (in seconds) should we wait between connection attempts?

          Default: 5 seconds.
        EDOC
      end
      has :client_id, :default => nil, :kind => String do
        doc <<-EDOC
          A string used to identify this script to the broken.
        EDOC
      end
      has :logfile, :default => STDERR do
        doc <<-EDOC
          Where should we log to?

          Default: STDERR.
        EDOC
      end
      has :logger, :default => nil do
        doc <<-EDOC
          A logger that's to log with. If this is left out of the options a
          new Logger is built that talks to the logfile.
        EDOC
      end
      has :subscription_name, :default => nil do
        doc <<-EDOC
          The subscription to consume from on the broker.

          This is only used by message consumers. It doesn't make much sense
          for message producers.
        EDOC
      end
      has :home, :default => File.dirname(File.expand_path(__FILE__)) do
        doc <<-EDOC
          A directory to store state in.

          Defaults to the directory this script is in.
        EDOC
      end
      has :single_delivery, :default => false do
        doc <<-EDOC
          Note: we can't guarantee single delivery - only best effort.
          Use this when receiving a message more than once is very
          costly. However, be aware that you ~will~ sometimes receive
          the same message more than once (so it's your responsibility
          to make sure that you guard against any consequences).
        EDOC
      end
      has :seen_messages_file do
        init { File.join(home, "seen_messages.#{subscription_name}.#{client_id}.yml") }
      end
      has :expires, :default => 86400 * 7 do
        doc <<-EDOC
          Time to live in milliseconds, i.e. a relative offset not an
          absolute time (as it would be in JMS).

          The default time to live is one week.
        EDOC
      end
      # to get a durable subscription, you must specify
      #   :durable => true
      # and a :client_id (and optionally a :subscription_name)
      has :durable, :default => false do
        must "be true or false" do |b|
          [true, false].include?(b)
        end
        doc <<-EDOC
          Specify whether you want a durable or non-durable subscription.

          Note: durable queues are ~not~ the default as this could be
          v. expensive in disk usage when used thoughtlessly.
        EDOC
      end
      must "specify client_id if durable is true" do
        #pp [:durable_test, client_id, durable, !client_id.to_s.strip.empty?]
        !(client_id.to_s.strip.empty? and durable)
      end
    end
    has :connection, :default => nil

    # seen_messages is used to skip over messages that have already
    # been seen - only activated when :single_delivery is specified
    has :seen_messages, :init => []
    has :seen_message_count, :init => 10
    has :seen_messages_file do
      init { configuration.seen_messages_file }
    end

    def initialize(*args, &block)
      super
      restore_remembered_messages
      SMQueue.dbg { [:seen_messages, seen_messages].inspect }
    end

    # handle an error
    def handle_error(exception_class, error_message, caller)
      #configuration.logger.warn error_message
      raise exception_class, error_message, caller
    end

    # connect to message broker
    def connect(*args, &block)
      self.connection = RStomp::Connection.open(configuration.to_hash)
      # If the connection has swapped hosts, then swap out primary and secondary
      if connection.current_host != configuration.host
        configuration.secondary_host = configuration.host
        configuration.host = connection.current_host
      end

      # If the connection has swapped ports, then swap out primary and secondary
      if connection.current_port != configuration.port
        configuration.secondary_port = configuration.port
        configuration.port = connection.current_port
      end
    end

    # normalize hash keys (top level only)
    # - normalizes keys to strings by default
    # - optionally pass in name of method to use (e.g. :to_sym) to normalize keys
    def normalize_keys(hash, method = :to_s)
      hash = hash.dup
      hash.keys.each do |k|
        normalized_key = k.respond_to?(method) ? k.send(method) : k
        hash[normalized_key] = hash.delete(k)
      end
      hash
    end

    # true if the message with this message_id has already been seen
    def message_seen?(message_id)
      self.seen_messages.include?(message_id)
    end

    # remember the message_id
    def message_seen(message_id)
      message_id = message_id.to_s.strip
      if message_id != ""
        self.seen_messages << message_id
        SMQueue.dbg { [:smqueue, :ack, :message_seen, message_id].inspect }
        if self.seen_messages.size > self.seen_message_count
          self.seen_messages.shift
        end
        store_remembered_messages
      else
        SMQueue.dbg { [:smqueue, :ack, :message_seen, message_id].inspect }
      end
    end

    # store the remembered message ids in a yaml file
    def store_remembered_messages
      if configuration.single_delivery
        File.open(seen_messages_file, 'w') do |file|
          file.write seen_messages.to_yaml
        end
      end
    end

    # reload remembered message ids from a yaml file
    def restore_remembered_messages
      if configuration.single_delivery
        yaml = default_yaml = "--- []"
        begin
          File.open(seen_messages_file, 'r') do |file|
            yaml = file.read
          end
        rescue Object
          yaml = default_yaml
        end
        buffer = []
        begin
          buffer = YAML.load(yaml)
          if !buffer.kind_of?(Array) or !buffer.all?{ |x| x.kind_of?(String)}
            raise Exception, "Invalid seen_messages.yml file"
          end
        rescue Object
          buffer = []
        end
        self.seen_messages = buffer
      end
    end

    # acknowledge message (if headers["ack"] == "client")
    def ack(subscription_headers, message)
      #p [:ack, message.headers["message-id"]]
      if message.headers["message-id"].to_s.strip != "" && subscription_headers["ack"].to_s == "client"
        SMQueue.dbg { [:smqueue, :ack, :message, message].inspect }
        connection.ack message.headers["message-id"], { }
      else
        SMQueue.dbg { [:smqueue, :ack, :not_acknowledging, message].inspect }
      end
      if ENV['PAUSE_SMQUEUE']
        $stderr.print "press enter to continue> "
        $stderr.flush
        $stdin.gets
      end
    end

    # get message from queue
    # - if block supplied, loop forever and yield(message) for each
    #   message received
    # default headers are:
    #   :ack               => "client"
    #   :client_id         => configuration.client_id
    #   :subscription_name => configuration.subscription_name
    #
    def get(headers = {}, &block)
      self.connect
      SMQueue.dbg { [:smqueue, :get, headers].inspect }
      subscription_headers = {"ack" => "client", "activemq.prefetchSize" => 1 }
      if client_id = configuration.client_id
        subscription_headers["client_id"] = client_id
      end
      if sub_name = configuration.subscription_name
        subscription_headers["subscription_name"] = sub_name
      end
      # if a client_id is supplied, then user wants a durable subscription
      # N.B. client_id must be unique for broker
      subscription_headers.update(headers)
      #p [:subscription_headers_before, subscription_headers]
      subscription_headers = normalize_keys(subscription_headers)
      if configuration.durable and client_id = configuration.client_id || subscription_headers["client_id"]
        subscription_name = configuration.subscription_name || subscription_headers["subscription_name"] || client_id
        # activemq only
        subscription_headers["activemq.subscriptionName"] = subscription_name
        # JMS
        subscription_headers["durable-subscriber-name"] = subscription_name
      end
      #p [:subscription_headers_after, subscription_headers]

      destination = configuration.name
      SMQueue.dbg { [:smqueue, :get, :subscribing, destination, :subscription_headers, subscription_headers].inspect }
      connection.subscribe destination, subscription_headers
      message = nil
      SMQueue.dbg { [:smqueue, :get, :subscription_headers, subscription_headers].inspect }
      begin
        # TODO: refactor this
        if block_given?
          SMQueue.dbg { [:smqueue, :get, :block_given].inspect }
          # todo: change to @running - (and set to false from exception handler)
          # also should check to see if anything left to receive on connection before bailing out
          while true
            SMQueue.dbg { [:smqueue, :get, :receive].inspect }
            # block until message ready
            message = connection.receive
            SMQueue.dbg { [:smqueue, :get, :received, message].inspect }
            case message.command
            when "ERROR"
              SMQueue.dbg { [:smqueue, :get, :ERROR, message].inspect }
            when "RECEIPT"
              SMQueue.dbg { [:smqueue, :get, :RECEIPT, message].inspect }
            else
              SMQueue.dbg { [:smqueue, :get, :yielding].inspect }
              if !message_seen?(message.headers["message-id"])
                yield(message)
              end
              SMQueue.dbg { [:smqueue, :get, :message_seen, message.headers["message-id"]].inspect }
              message_seen message.headers["message-id"]
              SMQueue.dbg { [:smqueue, :get, :returned_from_yield_now_calling_ack].inspect }
              ack(subscription_headers, message)
              SMQueue.dbg { [:smqueue, :get, :returned_from_ack].inspect }
            end
          end
        else
          SMQueue.dbg { [:smqueue, :get, :single_shot].inspect }
          message = connection.receive
          SMQueue.dbg { [:smqueue, :get, :received, message].inspect }
          if !(message.command == "ERROR" or message.command == "RECEIPT")
            SMQueue.dbg { [:smqueue, :get, :message_seen, message.headers["message-id"]].inspect }
            message_seen message.headers["message-id"]
            SMQueue.dbg { [:smqueue, :get, :ack, message].inspect }
            ack(subscription_headers, message)
            SMQueue.dbg { [:smqueue, :get, :returned_from_ack].inspect }
          end
        end
      rescue Object => e
        SMQueue.dbg { [:smqueue, :get, :exception, e].inspect }
        handle_error e, "Exception in SMQueue#get: #{e.message}", caller
      ensure
        SMQueue.dbg { [:smqueue, :get, :ensure].inspect }
        SMQueue.dbg { [:smqueue, :unsubscribe, destination, subscription_headers].inspect }
        connection.unsubscribe destination, subscription_headers
        SMQueue.dbg { [:smqueue, :disconnect].inspect }
        connection.disconnect
      end
      SMQueue.dbg { [:smqueue, :get, :return].inspect }
      message
    end

    # put a message on the queue
    # default headers are:
    #   :persistent => true
    #   :ack        => "auto"
    #   :expires    => configuration.expires
    def put(body, headers = { })
      body, headers = normalize_message(body, headers)
      SMQueue.dbg { [:smqueue, :put, body, headers].inspect }
      begin
        self.connect
        headers = {:persistent => true, :ack => "auto", :expires => SMQueue.calc_expiry_time(configuration.expires) }.merge(headers)
        destination = configuration.name
        SMQueue.dbg { [:smqueue, :send, body, headers].inspect }
        connection.send destination, body, headers
      rescue Exception => e
        SMQueue.dbg { [:smqueue, :exception, e].inspect }
        handle_error e, "Exception in SMQueue#put - #{e.message}", caller
        #connection.disconnect
      ensure
        connection.disconnect
      end
    end
  end
end
