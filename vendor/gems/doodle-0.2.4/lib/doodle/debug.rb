class Doodle
  # debugging utilities
  module Debug
    class << self
      # Robert Klemme, (ruby-talk 205150), (ruby-talk 205950)
      def calling_method(level = 1)
        caller[level] =~ /`([^']*)'/ and $1
      end

      def this_method
        calling_method
      end

      # output result of block if ENV['DEBUG_DOODLE'] set
      def d(&block)
        puts(calling_method + ": " + block.call.inspect) if ENV['DEBUG_DOODLE']
      end
    end
  end
end
