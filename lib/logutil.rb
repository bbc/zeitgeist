#
# logging utils
#
# provides global logger method to access the global @logger object
#
require 'rubygems'
require 'logging'
require 'fileutils'

module LogUtil
  class << self

    def base_path
      @base_path ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
    end

    def base_path=(base_path)
      @base_path = base_path
    end

    def create_logfile(basename = File.basename($0, '.rb'), filename = File.join(base_path, 'log', "#{basename}.log"), level = :info)
      base_dir = File.dirname(filename)
      FileUtils.mkdir_p(base_dir)
      #p [:create_logfile, basename, filename, level]
      @logger = Logging::Logger[basename]
      file_layout = Logging::Layouts::Pattern.new(
                                             # :pattern => "[%d] %c - %-5l : %m\n",
                                             #:pattern => "%d\t%c\t%l\t%m\n",
                                             #:pattern => "%d %c %-5l %m\n",
                                             :pattern => "[%c] %d - %-5l: %m\n",
                                             :date_pattern => "%Y-%m-%dT%H:%M:%S.%s"
                                             )

      # Log everything to stdout before trying to log to file
      stdout_layout = Logging::Layouts::Pattern.new(
                                                    # :pattern => "%c - %-5l : %m\n"
                                                    :pattern => "[%c] %d - %-5l: %m\n"
                                                    )
      @logger.add_appenders( Logging::Appenders::Stdout.new( :layout => stdout_layout ) )

      # @logger.add_appenders(
      #                       Logging::Appenders::RollingFile.new(filename,
      #                                                           :layout => file_layout,
      #                                                           :truncate => true,
      #                                                           :size => 1024 * 1024 * 10, # 10 Meg
      #                                                           :keep => 1,
      #                                                           :safe => true)
      #                       )

      #pp [:appenders, @logger.instance_eval {  @appenders }]
      #p [:level, @logger.level]
      @logger.level = level
      #p [:level, @logger.level]
      @logger
    end

    def logger
      @logger ||= create_logfile
    end
  end
end

def logger
  LogUtil.logger
end

if $0 == __FILE__
  LogUtil.base_path = "/tmp"
  logger.info "Hello World!"
  logger.level = :debug
  logger.debug "A longer message which contains all sorts of things |hello| [asdasd]!"
end
