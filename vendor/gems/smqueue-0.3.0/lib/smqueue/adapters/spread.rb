require 'spread'

module SMQueue
  class SpreadAdapter < Adapter
    class Configuration < AdapterConfiguration
      has :channel do
        rx_hostname = /[a-z_\.]+/
        rx_ip = /\d+(\.\d+){3}/ # dotted quad
        must 'be a name in the form "port", "port@hostname", or "port@ip"' do |s|
          s =~ /\d+(@(#{rx_hostname})|(#{rx_ip}))?/
        end
      end
      has :group do
        doc "a group name or array of group names"
        must "be either a String group name or an array of group names" do |s|
          s.kind_of?(String) || (s.kind_of?(Array) && s.all?{ |x| x.kind_of?(String)})
        end
      end
      has :private_name, :default => '' do
        doc <<EDOC
private_name is the name of this connection. It must be unique among
all the connections to a given Spread daemon. If not specified, Spread
will assign a randomly-generated unique private name.
EDOC
      end
      has :all_messages, :default => false do
        doc <<EDOC
all_messages indicates whether this connection should receive all
Spread messages, or just data messages.
EDOC
      end
      has :service_type, :default => Spread::AGREED_MESS do
        service_type_map = {
          :unreliable => Spread::UNRELIABLE_MESS,
          :reliable => Spread::RELIABLE_MESS,
          :fifo => Spread::FIFO_MESS,
          :causal => Spread::CAUSAL_MESS,
          :agreed => Spread::AGREED_MESS,
          :safe => Spread::SAFE_MESS,
          :regular => Spread::REGULAR_MESS,
        }
        from Symbol, String do |s|
          s = s.to_s.to_sym
          if service_type_map.key?(s)
            service_type_map[s]
          else
            raise Doodle::ConversionError, "Did not recognize service_type #{s.inspect} - should be one of #{service_type_map.keys.inspect}"
          end
        end
      end
    end

    has :connection, :default => nil
    has :connected, :default => false

    def connect
      @connection = Spread::Connection.new(configuration.channel, configuration.private_name, configuration.all_messages )
      connection.join(configuration.group)
      configuration.private_name = connection.private_group
      connected true
    end
    def disconnect
      connection.leave group
      connection.disconnect
      connected false
    end
    def get(&block)
      m = nil
      connect if !connected
      loop do
        msg = connection.receive
        if msg.data?
          m = SMQueue::Message.new(
                               :headers => {
                                 :private_name => configuration.private_name,
                                 :sender => msg.sender,
                                 :type => msg.msg_type,
                                 :groups => msg.groups,
                                 :reliable => msg.reliable?,
                                 :safe => msg.safe?,
                                 :agreed => msg.agreed?,
                                 :causal => msg.causal?,
                                 :fifo => msg.fifo?,
                               },
                               :body => msg.message
                               )
          if block_given?
            yield(m)
          else
            break
          end
        end
      end
      m
    end
    def put(body, headers = { })
      body, headers = normalize_message(body, headers)
      connect if !connected
      connection.multicast(msg, configuration.group, configuration.service_type, msg_type = 0, self_discard = true)
    end
  end
end
