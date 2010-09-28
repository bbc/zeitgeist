## requires
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require 'datamapper'
require 'time'

require 'config'
require 'dbobject'
require LoadPath.app_path('models')

## set up db connection
# load configuration
config = ConfigHelper.load_config("database.yml")

db_config = config[:development]
port_string = db_config[:port]
if port_string
  port_string = ":#{port_string}"
end

# user:password@host[:port]/database
MYSQL_CONNECT_STRING = "#{db_config[:user]}:#{db_config[:password]}@#{db_config[:host]}#{port_string}/#{db_config[:database]}"

# DataMapper.setup(:default, "sqlite3::memory:")
# DataMapper.setup(:default, "sqlite3:#{LoadPath.base_dir("var", "development.db")}")

DataMapper.setup(:default, "mysql://#{MYSQL_CONNECT_STRING}?encoding=UTF-8")

## create schema if necessary
DataMapper.auto_upgrade!

