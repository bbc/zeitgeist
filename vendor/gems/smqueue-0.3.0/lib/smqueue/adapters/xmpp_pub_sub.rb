require 'thread'                # for Queue
require 'pp'

require 'xmpp4r'
require "xmpp4r/pubsub"
require "xmpp4r/pubsub/helper/servicehelper.rb"
require "xmpp4r/pubsub/helper/nodebrowser.rb"
#require "xmpp4r/pubsub/helper/nodehelper.rb"

Thread.abort_on_exception = true

module REXML
  # derived from http://www.koders.com/ruby/fid3712196E67D4522F76EAD9F57078E4D0736746C5.aspx?s=update
  class Element # :nodoc:
    unless REXML::Element.public_instance_methods.include?(:inner_xml)
      def inner_xml # :nodoc:
        result = []
        each_child do |child|
          if child.kind_of?(REXML::Comment)
            result << "<!--" + child.to_s + "-->"
          else
            result << child.to_s
          end
        end
        result.join('').strip
      end
    else
      warn("inner_xml method already exists.")
    end
  end
end

module SMQueue
  class XMPPPubSubAdapter < Adapter
    include Jabber

    class Configuration < AdapterConfiguration

      has :host, :kind => String, :default => "" do
        doc <<-EDOC
          The host that runs the broker you want to connect to.
        EDOC
      end

      has :logger do
        default { Logger.new(STDERR) }
        doc <<-EDOC
          The logger to use - must provide #info, #debug, #warn.
          If this is not specified, a default Logger is set up
          to log to STDERR.
        EDOC
      end

      # note: this configured node is not identical to the one defined
      # (and used) below - this defines the leaf path which is later
      # expanded to the full path to the node below
      has :node, :default => nil do
        doc <<-EDOC
          The node to publish/subscribe to.
        EDOC
      end

      has :jid, :default => "" do
        doc <<-end
          The Jabber ID.
        end
      end

      has :password, :kind => String, :default => "" do
        doc <<-EDOC
          The password to attempt to authenticate at the broker with.
          If you are using an anonymous subscription, leave this blank.
        EDOC
      end

      has :service

      has :anonymous, :default => false do
        doc <<-end
          Set to true to use SASL anonymous authentication.
        end
      end

      has :debug, :default => false, :doc => "set to true to get XMPP debug info" do
        from Object do |s|
          flag = !!s
          if flag
            Jabber.debug = flag
          end
          flag
        end
      end

      has :xpath, :default => nil
    end

    has :connected, :default => false
    has :subscribed, :default => false

    has :node do
      init { "home/#{configuration.host}/#{configuration.node}"}
    end

    has :service do
      init { "#{configuration.service}.#{configuration.host}"}
    end

    has :logger do
      init { configuration.logger }
    end

    def connect
      pp self.doodle.key_values

      @client = Jabber::Client.new(Jabber::JID.new(configuration.jid))
      rv = @client.connect(configuration.host)
      logger.info "client.connect: #{rv}"

      if @client.supports_anonymous? && configuration.anonymous
        logger.info "connecting anonymously"
        @client.auth_anonymous_sasl
      else
        logger.info "connecting with password: #{!configuration.password.nil?}"
        @client.auth(configuration.password)
      end
      @client.send(Jabber::Presence.new.set_type(:available))

      @pubsub = Jabber::PubSub::ServiceHelper.new(@client, service)
      connected true
    end

    def subscribe
      logger.info "\n\nSubscribing\n\n"
      @pubsub.subscribe_to(node)
      subscribed true
      @callbacks = @pubsub.add_event_callback do |event|
        # logger.info "received #{event.inspect}"
        logger.info "Received " + event.inspect
        event.payload.each do |e|
          logger.info "payload.e " + e.inspect
          REXML::XPath.each(e, configuration.xpath) do |el|
            logger.info "queuing: #{el.inner_xml}"
            @event_queue.enq(el.inner_xml)
          end
        end
      end
      logger.debug "after callback definition"
    end

    def unsubscribe
      @pubsub.unsubscribe_from(node) if subscribed
    end

    def disconnect
      begin
        unsubscribe
        @client.close
      ensure
        connected false
      end
    end

    def get(&block)
      logger.debug "get"
      m = nil
      connect if !connected
      @event_queue = Queue.new
      subscribe if !subscribed

      loop do
        logger.debug "# queued events #{@event_queue.size}"
        logger.info "waiting for msg"
        payload = @event_queue.deq
        logger.info "PAYLOAD: #{payload.inspect}"
        m = SMQueue::Message.new(
                                 :headers => {
                                   :protocol => :xmpp
                                 },
                                 :body => payload
                                 )
        if block_given?
          yield(m)
        else
          break
        end
      end
      m
    end

    def put(body, headers = { })
      body, headers = normalize_message(body, headers)
      logger.debug "put #{body.inspect}"
      connect if !connected
      item = PubSub::Item.new
      xml = REXML::Element.new("message")
      xml.text = body
      item.add(xml);
      @pubsub.publish_item_to(node, item)
    end
  end
end
