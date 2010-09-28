#
# = net/protocol.rb
#
#--
# Copyright (c) 1999-2005 Yukihiro Matsumoto
# Copyright (c) 1999-2005 Minero Aoki
#
# written and maintained by Minero Aoki <aamine@loveruby.net>
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms as Ruby itself,
# Ruby Distribute License or GNU General Public License.
#
# $Id: protocol.rb 12092 2007-03-19 02:39:22Z aamine $
#++
#
# WARNING: This file is going to remove.
# Do not rely on the implementation written in this file.
#
# <2009-12-14 Mon> 15:03:17 - override rbuf_fill to use
#   readpartial (which retries on EINTR) instead of sysread (which
#   lets EINTR through) - Sean O'Halpin

require 'socket'
require 'timeout'

module Net # :nodoc:
  class BufferedIO   #:nodoc: internal use only
    private

    if !self.const_defined?(:BUFSIZE)
      BUFSIZE = 1024 * 16
    end

    def rbuf_fill
      timeout(@read_timeout) {
        # @rbuf << @io.sysread(BUFSIZE)
        @rbuf << @io.readpartial(BUFSIZE)
      }
    end
  end

end   # module Net
