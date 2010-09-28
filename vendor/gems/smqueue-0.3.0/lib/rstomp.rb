#   Copyright 2005-2006 Brian McCallister
#   Copyright 2006 LogicBlaze Inc.
#   Copyright 2008 Sean O'Halpin
#   - refactored to use params hash
#   - made more 'ruby-like'
#   - use logger instead of $stderr
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'io/wait'
require 'socket'
require 'thread'
require 'stringio'
require 'logger'


# use keepalive to detect dead connections (see http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/)

module SocketExtensions
  # Linux
  module Linux
    # /usr/include/netinet/tcp.h
    TCP_KEEPIDLE  = 4
    TCP_KEEPINTVL = 5
    TCP_KEEPCNT   = 6
  end
  module Darwin
    # Mac OSX
    # tcp.h:#define TCP_KEEPALIVE     0x10    /* idle time used when SO_KEEPALIVE is enabled */
    TCP_KEEPALIVE = 0x10
    # these are sysctl vars
    # /usr/include/netinet/tcp_var.h:#define  TCPCTL_KEEPIDLE         6       /* keepalive idle timer */
    # /usr/include/netinet/tcp_var.h:#define  TCPCTL_KEEPINTVL        7       /* interval to send keepalives */
    # /usr/include/netinet/tcp_var.h:#define  TCPCTL_KEEPINIT         10      /* timeout for establishing syn */  end
  end
end


if $DEBUG
  require 'pp'
end

module RStomp
  class RStompException < Exception
  end
  class ConnectionError < RStompException
  end
  class ReceiveError < RStompException
  end
  class InvalidContentLengthError < RStompException
  end
  class TransmitError < RStompException
  end
  class NoListenerError < RStompException
  end
  class NoDataError < RStompException
  end
  class InvalidFrameTerminationError < RStompException
  end

  # Low level connection which maps commands and supports
  # synchronous receives
  class Connection
    attr_reader :current_host, :current_port

    DEFAULT_OPTIONS = {
      :user => "",
      :password => "",
      :host => 'localhost',
      :port => 61613,
      :reliable => false,
      :reconnect_delay => 5,
      :client_id => nil,
      :logfile => STDERR,
      :logger => nil,
    }

    # make them attributes
    DEFAULT_OPTIONS.each do |key, value|
      attr_accessor key
    end

    def Connection.open(params = {})
      params = DEFAULT_OPTIONS.merge(params)
      Connection.new(params)
    end

    # Create a connection
    # Options:
    # - :user => ''
    # - :password => ''
    # - :host => 'localhost'
    # - :port => 61613
    # - :reliable => false    (will keep retrying to send if true)
    # - :reconnect_delay => 5 (seconds)
    # - :client_id => nil     (used in durable subscriptions)
    # - :logfile => STDERR
    # - :logger => Logger.new(params[:logfile])
    #
    def initialize(params = {})
      params = DEFAULT_OPTIONS.merge(params)
      @host = params[:host]
      @port = params[:port]
      @secondary_host = params[:secondary_host]
      @secondary_port = params[:secondary_port]

      @current_host = @host
      @current_port = @port

      @user = params[:user]
      @password = params[:password]
      @reliable = params[:reliable]
      @reconnect_delay = params[:reconnect_delay]
      @client_id = params[:client_id]
      @logfile = params[:logfile]
      @logger = params[:logger] || Logger.new(@logfile)

      @transmit_semaphore = Mutex.new
      @read_semaphore = Mutex.new
      @socket_semaphore = Mutex.new

      @subscriptions = {}
      @failure = nil
      @socket = nil
      @open = false

      socket
    end

    # set default TCP_KEEPALIVE option to prevent waiting forever on
    # half-open connection after server crash
    def socket_set_keepalive(s)
      # use keepalive to detect dead connections (see http://tldp.org/HOWTO/TCP-Keepalive-HOWTO/)
      s.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)

      case RUBY_PLATFORM
      when /linux/
        # note: if using OpenSSL, you may need to do this:
        #   ssl_socket.to_io.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        # see http://www.lerfjhax.com/articles/2006/08/22/ruby-ssl-setsockopt

        # defaults
        # $ cat /proc/sys/net/ipv4/tcp_keepalive_time
        # 7200
        # $ cat /proc/sys/net/ipv4/tcp_keepalive_intvl
        # 75
        # $ cat /proc/sys/net/ipv4/tcp_keepalive_probes
        # 9

        # these values should all be configurable (but with sensible defaults)

        # TCP_KEEPIDLE: the interval between the last data packet sent (simple
        # ACKs are not considered data) and the first keepalive
        # probe; after the connection is marked to need
        # keepalive, this counter is not used any further
        s.setsockopt(Socket::IPPROTO_TCP, SocketExtensions::Linux::TCP_KEEPIDLE, 20)
        # TCP_KEEPINTVL: the interval between subsequential keepalive probes,
        # regardless of what the connection has exchanged in the
        # meantime
        s.setsockopt(Socket::IPPROTO_TCP, SocketExtensions::Linux::TCP_KEEPINTVL, 10)
        # TCP_KEEPCNT: the number of unacknowledged probes to send before
        # considering the connection dead and notifying the
        # application layer
        #
        # NOTE: I did not see any effect from setting this
        # option
        s.setsockopt(Socket::IPPROTO_TCP, SocketExtensions::Linux::TCP_KEEPCNT, 6)
      when /darwin/
        # this works, with value = 100 actually takes 12 minutes
        # 55 secs to time out (with opt = 100); with value = 10,
        # takes 685 seconds

        # ttl = KEEPIDLE + (9 * 75) - cannot change INTVL and
        # CNT per socket on Darwin

        # TCP_KEEPALIVE: set KEEPIDLE time (in seconds) - wait
        # one minute before sending KEEPALIVE packet
        opt = [60].pack('l')
        s.setsockopt(Socket::IPPROTO_TCP, SocketExtensions::Darwin::TCP_KEEPALIVE, opt)
      when /jruby/
      else
      end
      s
    end

    def socket
      # Need to look into why the following synchronize does not work. (SOH: fixed)
      # SOH: Causes Exception ThreadError 'stopping only thread note: use sleep to stop forever' at 235
      # SOH: because had nested synchronize in _receive - take outside _receive (in receive) and seems OK
      @socket_semaphore.synchronize do
        s = @socket
        headers = {
          :user => @user,
          :password => @password
        }
        headers['client-id'] = @client_id unless @client_id.nil?
        # logger.debug "headers = #{headers.inspect} client_id = #{ @client_id }"
        while s.nil? or @failure != nil
          begin
            #p [:connecting, :socket, s, :failure, @failure, @failure.class.ancestors, :closed, closed?]
            # logger.info( { :status => :connecting, :host => host, :port => port }.inspect )
            @failure = nil

            s = TCPSocket.open(@current_host, @current_port)
            socket_set_keepalive(s)

            _transmit(s, "CONNECT", headers)
            @connect = _receive(s)
            @open = true

            # replay any subscriptions.
            @subscriptions.each { |k, v| _transmit(s, "SUBSCRIBE", v) }
          rescue Interrupt => e
            #p [:interrupt, e]
            #          rescue Exception => e
          rescue RStompException, SystemCallError => e
            #p [:Exception, e]
            @failure = e
            # ensure socket is closed
            begin
              s.close if s
            rescue Object => e
            end
            s = nil
            @open = false

            switch_host_and_port unless @secondary_host.empty?

            handle_error ConnectionError, "connect failed: '#{e.message}' will retry in #{@reconnect_delay} on #{@current_host} port #{@current_port}", host.empty?
            sleep(@reconnect_delay)
          end
        end
        @socket = s
      end
    end

    def switch_host_and_port
      # Try connecting to the slave instead
      # Or if the slave goes down, connect back to the master
      # if it's not a reliable queue, then if the slave queue doesn't work then fail
      if !@reliable && ((@current_host == @secondary_host) && (@current_port == @secondary_port))
        @current_host = ''
        @current_port = ''
      else # switch the host from primary to secondary (or back again)
        @current_host = (@current_host == @host ? @secondary_host : @host)
        @current_port = (@current_port == @port ? @secondary_port : @port)
      end
    end

    # Is this connection open?
    def open?
      @open
    end

    # Is this connection closed?
    def closed?
      !open?
    end

    # Begin a transaction, requires a name for the transaction
    def begin(name, headers = {})
      headers[:transaction] = name
      transmit "BEGIN", headers
    end

    # Acknowledge a message, used then a subscription has specified
    # client acknowledgement ( connection.subscribe "/queue/a", :ack => 'client' )
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def ack(message_id, headers = {})
      headers['message-id'] = message_id
      transmit "ACK", headers
    end

    # Commit a transaction by name
    def commit(name, headers = {})
      headers[:transaction] = name
      transmit "COMMIT", headers
    end

    # Abort a transaction by name
    def abort(name, headers = {})
      headers[:transaction] = name
      transmit "ABORT", headers
    end

    # Subscribe to a destination, must specify a name
    def subscribe(name, headers = {}, subscription_id = nil)
      headers[:destination] = name
      transmit "SUBSCRIBE", headers

      # Store the sub so that we can replay if we reconnect.
      if @reliable
        subscription_id = name if subscription_id.nil?
        @subscriptions[subscription_id]=headers
      end
    end

    # Unsubscribe from a destination, must specify a name
    def unsubscribe(name, headers = {}, subscription_id = nil)
      headers[:destination] = name
      transmit "UNSUBSCRIBE", headers
      if @reliable
        subscription_id = name if subscription_id.nil?
        @subscriptions.delete(subscription_id)
      end
    end

    # Send message to destination
    #
    # Accepts a transaction header ( :transaction => 'some_transaction_id' )
    def send(destination, message, headers = {})
      headers[:destination] = destination
      transmit "SEND", headers, message
    end

    # drain socket
    def discard_all_until_eof
      @read_semaphore.synchronize do
        while @socket do
          break if @socket.gets.nil?
        end
      end
    end
    private :discard_all_until_eof

    # Close this connection
    def disconnect(headers = {})
      transmit "DISCONNECT", headers
      discard_all_until_eof
      begin
        @socket.close
      rescue Object => e
      end
      @socket = nil
      @open = false
    end

    # TODO: do I really want this?
    # Return a pending message if one is available, otherwise
    # return nil
    def poll
      @read_semaphore.synchronize do
        if @socket.nil? or !@socket.ready?
          nil
        else
          receive
        end
      end
    end

    # Receive a frame, block until the frame is received
    def receive
      # The receive may fail so we may need to retry.
      # TODO: use retry count?
      while true
        begin
          s = socket
          rv = _receive(s)
          return rv
          #        rescue Interrupt
          #          raise
        rescue RStompException, SystemCallError => e
          @failure = e
          handle_error ReceiveError, "receive failed: #{e.message}"
          # TODO: maybe sleep here?
        end
      end
    end

    private
    def _receive( s )
      #logger.debug "_receive"
      line = ' '
      @read_semaphore.synchronize do
        #logger.debug "inside semaphore"
        # skip blank lines
        while line =~ /^\s*$/
          #logger.debug "skipping blank line " + s.inspect
          line = s.gets
        end
        if line.nil?
          # FIXME: this loses data - maybe retry here if connection returns nil?
          raise NoDataError, "connection returned nil"
          nil
        else
          #logger.debug "got message data"
          Message.new do |m|
            m.command = line.chomp
            m.headers = {}
            until (line = s.gets.chomp) == ''
              k = (line.strip[0, line.strip.index(':')]).strip
              v = (line.strip[line.strip.index(':') + 1, line.strip.length]).strip
              m.headers[k] = v
            end

            if m.headers['content-length']
              m.body = s.read m.headers['content-length'].to_i
              # expect an ASCII NUL (i.e. 0)
              c = s.getc
              handle_error InvalidContentLengthError, "Invalid content length received" unless c == 0
            else
              m.body = ''
              until (c = s.getc) == 0
                m.body << c.chr
              end
            end
            if $DEBUG
              logger.debug "Message #: #{m.headers['message-id']}"
              logger.debug "  Command: #{m.command}"
              logger.debug "  Headers:"
              m.headers.sort.each do |key, value|
                logger.debug "    #{key}: #{m.headers[key]}"
              end
              logger.debug "  Body: [#{m.body}]\n"
            end
            m
            #c = s.getc
            #handle_error InvalidFrameTerminationError, "Invalid frame termination received" unless c == 10
          end
        end
      end
    end

    private

    # route all error handling through this method
    def handle_error(exception_class, error_message, force_raise = !@reliable)
      logger.warn error_message
      # if not an internal exception, then raise
      if !(exception_class <= RStompException)
        force_raise = true
      end
      raise exception_class, error_message if force_raise
    end

    def transmit(command, headers = {}, body = '')
      # The transmit may fail so we may need to retry.
      # TODO: Maybe use retry count?
      while true
        begin
          _transmit(socket, command, headers, body)
          return
          #        rescue Interrupt
          #          raise
        rescue RStompException, SystemCallError => e
          @failure = e
          handle_error TransmitError, "transmit '#{command}' failed: #{e.message} (#{body})"
        end
        # TODO: sleep here?
      end
    end

    private
    def _transmit(s, command, headers={}, body='')
      msg = StringIO.new
      msg.puts command
      headers.each {|k, v| msg.puts "#{k}: #{v}" }
      msg.puts "content-length: #{body.nil? ? 0 : body.length}"
      if !headers["content-type"]
        msg.puts "content-type: text/plain; charset=UTF-8"
      end
      msg.puts
      msg.write body
      msg.write "\0"
      if $DEBUG
        msg.rewind
        logger.debug "_transmit"
        msg.read.each_line do |line|
          logger.debug line.chomp
        end
      end
      msg.rewind
      @transmit_semaphore.synchronize do
        s.write msg.read
      end
    end
  end

  # Container class for frames (misnamed - should be Frame)
  class Message
    attr_accessor :headers, :body, :command

    def initialize(&block)
      yield(self) if block_given?
    end

    def to_s
      "<#{self.class} headers=#{headers.inspect} body=#{body.inspect} command=#{command.inspect} >"
    end
  end

end
