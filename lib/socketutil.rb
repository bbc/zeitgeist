require 'socket'

module SocketUtil
  ## local_ip - get local IP address without making a connection or sending any packets
  # from http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
  def local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
  extend self
end
