require File.join(File.dirname(__FILE__), 'lib/load_paths')
require LoadPath.app_path('app')
require 'mw'
require 'rack/cache'
require 'rack/contrib'

#use MW
use Rack::Static, :urls => ["/css", "/images", "/js", "favicon.ico"], :root => "public"
use Rack::Deflater
use Rack::ETag
use Rack::Cache,
  :verbose     => true,
  :metastore   => 'file:/var/cache/rack/meta',
  :entitystore => 'file:/var/cache/rack/body'

run ZeitgeistApp
