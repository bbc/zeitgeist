require File.join(File.dirname(__FILE__), '../lib/load_paths')
#p 5
require 'logger'
def logger
  @logger ||= Logger.new(STDOUT)
end
#p 1
require 'data_objects'
#p 2
require 'datamapper'
DataMapper::Logger.new($stdout, :debug)
#p 3
require LoadPath.app_path("db")
#p 4
require LoadPath.model_path("queries")
#p 6
require 'code_timer'
#p 7

