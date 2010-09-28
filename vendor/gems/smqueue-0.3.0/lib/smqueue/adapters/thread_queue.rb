require 'thread'

module SMQueue
  class ThreadQueueAdapter < Adapter
    QUEUES = { }
    class Configuration < AdapterConfiguration
      def initialize(*args, &block)
        #p [self.class, args]
        super
      end
      has :name, :kind => String  do
        doc "symbolic name for queue"
        from Symbol do |s|
          s.to_s
        end
      end
    end

    class << self
      def new(params)
        config = params[:configuration]
        name = config[:name]
        if QUEUES.key?(config[:name])
          QUEUES[name]
        else
          QUEUES[name] = super(params)
        end
      end
    end

    doc "in memory threadsafe queue"
    has :thread_queue do
      doc "internal ref to thread-safe Queue"
      init { Queue.new }
    end

    def initialize(*args, &block)
      super
      QUEUES[configuration.name] = self
    end

    def put(body, headers = { }, &block)
      body, headers = normalize_message(body, headers)
      msg = SMQueue::Message.new(body, headers)
      #p [:tput, args]
      thread_queue.enq(msg)
    end

    def get(*args, &block)
      #p [:tget]
      loop do
        #p [:tget, :loop]
        input = thread_queue.deq
        if input.kind_of?(SMQueue::Message)
          msg = input
        else
          msg = SMQueue::Message.new(:body => input)
        end
        yield(msg)
      end
    end
  end
end

