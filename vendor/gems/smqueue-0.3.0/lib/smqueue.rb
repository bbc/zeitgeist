# SMQueue
# Simple Message Queue client
# Sean O'Halpin, 2008

# The high-level client API is:
# - SMQueue(config).put msg, headers = {}
# - msg = SMQueue(config).get(headers = {})
# - SMQueue(config).get(headers = {}) do |msg|
#   end
# todo - [X] add :durable option (and fail if no client_id specified)
# todo - [x] gemify - use Mr Bones
# todo - [ ] change to class (so can be subclassed) - so you're working with an SMQueue instance
# todo - [ ] write protocol (open, close, put, get) in SMQueue (so don't have to do it in adaptors)
# todo - [ ] simplify StompAdapter (get rid of sent_messages stuff)
# todo - [ ] simplify adapter interface
# todo - [ ] sort out libpath

require 'rubygems'
require 'doodle'
require 'yaml'

#class SMQueue < Doodle
module SMQueue

  # Mr Bones project skeleton boilerplate
  # :stopdoc:
  VERSION = '0.3.0'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
                                   ::File.join(::File.dirname(fname), dir, '*', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

  # end Bones boilerplate

  module ClassMethods
    def dbg(*args, &block)
      if ENV["DEBUG_SMQUEUE"]
        if args.size > 0
          STDERR.print "SMQUEUE.DBG: "
          STDERR.puts(*args)
        end
        if block_given?
          STDERR.print "SMQUEUE.DBG: "
          STDERR.puts(block.call)
        end
      end
    end

    # JMS expiry time in milliseconds from now
    def calc_expiry_time(seconds = 86400 * 7) # one week
      ((Time.now.utc + seconds).to_f * 1000).to_i
    end

    # resolve a string representing a classname
    def const_resolve(constant, start = self)
      #Doodle::Utils.const_resolve(constant)
      constant.to_s.split(/::/).reject{|x| x.empty?}.inject(start) { |prev, this| prev.const_get(this) }
    end
  end
  extend ClassMethods

  class AdapterConfiguration < Doodle
    has :name, :default => ""
    has :logger, :default => nil
    has :client_id, :default => nil

    def to_hash
      doodle.attributes.inject({}) {|hash, (name, attribute)| hash[name] = send(name); hash}
    end
    # need to use custom to_yaml because YAML won't serialize classes
    def to_yaml(*opts)
      to_hash.to_yaml(*opts)
    end
    def initialize(*args, &block)
      #p [self.class, :initialize, args, caller]
      super
    end
    has :adapter_class, :kind => Class do
      from String, Symbol do |s|
        s = s.to_s
        if s !~ /Adapter$/
          #s = "#{s.capitalize}Adapter"
          s = "#{Doodle::Utils.camelcase(s)}Adapter"
        end
        SMQueue.const_resolve(s.to_s)
      end

      # Note: use closure so this is not evaluated until after NullAdapter class has been defined
      default { NullAdapter }
    end
#     has :configuration_class, :kind => Class do
#       init { adapter_class::Configuration }
#       #init { adapter_class.const_get(:Configuration) }
#       from String do |s|
#         #Doodle::Utils.const_resolve(s)
#         SMQueue.const_resolve(s.to_s)
#       end
#     end

    def self.create(options)
      # TODO: make the AdapterConfiguration a factory class so it's
      # responsible for handling klass.new, e.g. so can decide which
      # class, whether to return existing instance, etc.
      ac = AdapterConfiguration.new(:adapter_class => options[:adapter_class])
      klass = ac.adapter_class
      #p [:klass, klass]
      klass.new(:configuration => options[:configuration])
    end

  end

  class Adapter < Doodle
    has :configuration, :kind => AdapterConfiguration, :abstract => true, :default => { } do
      from Hash do |h|
        #p [:Adapter, :configuration_from_hash]
        Doodle.context.last.class::Configuration.new(h)
      end
      from Object do |h|
        #p [:Adapter, :configuration_from_object, h.inspect, h.class]
        h
      end
    end

    # these are the core methods
    def get(*args, &block)
    end
    def normalize_message(body, headers)
      # p [:normalize_message, body, headers]
      if body.kind_of?(SMQueue::Message)
        headers = body.headers.merge(headers)
        body = body.body
      end
      [body, headers]
    end
    def put(*args, &block)
    end
    def self.create(configuration)
      # FIXME: dup config, otherwise can use it only once (because
      # delete :adapter) - prob. better way to do this
      configuration = configuration.dup
      adapter = configuration.delete(:adapter)
      #p [:adapter, adapter]
      ac = AdapterConfiguration.new(:adapter_class => adapter)
      #p [:ac, ac]
      klass = ac.adapter_class
      #p [:class, klass]
      #puts [:configuration, configuration].pretty_inspect
      #      klass.new(:configuration => configuration)
      klass.new(:configuration => configuration)
    end
  end

  class NullAdapter < Adapter
    def name
      "null"
    end
    class Configuration < AdapterConfiguration
    end
  end

  class Message < Doodle
    has :headers, :default => { }
    has :body
  end

  class << self
    def default_config_path
      "config/smq.yml"
    end
    def new(*args, &block)
      # FIXME: this is a mess because I'm supporting too many ways to initialize
      begin
        a = args.first
        #p [:new, :args_first, a]
        if a.kind_of?(Hash)
          if a.key?(:configuration)
            #p [:new, :config_hash, a]
            config = a[:configuration]
          else
            config = a
          end
        elsif args.size == 1 && a.kind_of?(Symbol) || a.kind_of?(String)
          #p [:new, :default_config, a]
          if !File.exist?(default_config_path)
            raise RuntimeError, "Cannot find configuration file (default is #{default_config_path})"
          end
          @config ||= YAML::load(File.read(default_config_path))
          #p [:new, :default_config, @config]
          config = @config[a]
          if config.nil?
            raise NameError, "Configuration #{a.inspect} not found in config file #{default_config_path}"
          end
        end
        #p [:new, :args, args]
        if args.nil?
          raise ArgumentError
        end
        # FIXME: hack to get around singleton can't be dumped
        tmp_logger = config[:logger]
        config[:logger] = nil
        config = Doodle::Utils.symbolize_keys(config, true)
        config[:logger] = tmp_logger

        #p [:create, args, config]
        Adapter.create(config, &block)
      rescue TypeError, ArgumentError => e
        raise ArgumentError, "Bad args to SMQueue.new - #{args.inspect}. If using a message_queue.yml, check for spelling mistake."
      end
    end
  end

end
def SMQueue(*args, &block)
  SMQueue.new(*args, &block)
end

# SMQueue.require_all_libs_relative_to(__FILE__)

# require adapters relative to invocation path first, then from lib
# [$0, __FILE__].each do |path|
#   base_path = File.expand_path(File.dirname(path))
#   adapter_path = File.join(base_path, 'smqueue', 'adapters', '*.rb')
#   Dir[adapter_path].each do |file|
#     begin
#       SMQueue.dbg "requiring #{file}"
#       require file
#     rescue Object => e
#       # warn "warning: could not load adapter '#{file}'. Reason: #{e}"
#     end
#   end
# end
base_dir = File.expand_path(File.dirname(__FILE__))
SMQueue.autoload :AMQPAdapter, File.join(base_dir, "smqueue/adapters/amqp.rb")
SMQueue.autoload :StdioAdapter, File.join(base_dir, "smqueue/adapters/stdio.rb")
SMQueue.autoload :ReadlineAdapter, File.join(base_dir, "smqueue/adapters/stdio.rb")
SMQueue.autoload :StdioLineAdapter, File.join(base_dir, "smqueue/adapters/stdio.rb")
SMQueue.autoload :StderrAdapter, File.join(base_dir, "smqueue/adapters/stdio.rb")

[$0, __FILE__].map{ |path| File.expand_path(File.dirname(path)) }.uniq.each do |base_path|
  #p [:base_path, base_path]
  adapter_path = File.join(base_path, 'smqueue', 'adapters', '*.rb')
  Dir[adapter_path].each do |file|
    begin
      basename = File.basename(file, File.extname(file))
      const_name_prefix = Doodle::Utils.camelcase(basename)
      # p [:file, file, basename, const_name_prefix]
      const_name = "#{const_name_prefix}Adapter"
      #p [:file, file, const_name]
      SMQueue.autoload const_name, file
    rescue Object => e
      warn "warning: could not load adapter '#{file}'. Reason: #{e}"
    end
  end
end

if __FILE__ == $0
  yaml = %[
:adapter: :StompAdapter
:host: localhost
:port: 61613
:name: /topic/smput.test
:reliable: true
:reconnect_delay: 5
:subscription_name: test_stomp
:client_id: hello_from_stomp_adapter
:durable: false
]

  adapter = SMQueue(:configuration => YAML.load(yaml))
  adapter.get do |msg|
    puts msg.body
  end

end

