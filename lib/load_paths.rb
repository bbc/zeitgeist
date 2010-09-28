# load_paths.rb
#
# Sean O'Halpin, <2010-03-19 Fri 12:55:43>
#
# Adds gem libraries from vendor directory to front of load path,
# assuming a Rails-like directory layout.
#
# If your script is in $APP/bin or $APP/scripts, use a preamble like
# this:
#
#   require File.join(File.dirname(__FILE__), '../lib/load_paths')
#
# then require libraries as usual.
#

require 'rubygems'
require 'bundler/setup'

module LoadPath
  def self.reload; Kernel.load __FILE__; end

  def base_path(*path)
    File.expand_path(File.join(File.dirname(__FILE__), '..', *path))
  end

  def base_dir(*path)
    base_path(*path)
  end

  def self.def_path(name)
    define_method "#{name}_path" do |*args|
      base_path(name.to_s, *args)
    end
  end

  [
   "app",
   "config",
   "lib",
   "public",
   "var",
   "vendor",
   "views",
  ].each do |name|
    def_path name
  end

  def model_path(*path)
    app_path("models", *path)
  end

  def css_path(*path)
    public_path("css", *path)
  end

  def load_all(*paths)
    Dir[File.join(*(paths + ["*.rb"]))].each do |path|
      require path
    end
  end

  def add_paths(*paths)
    paths.each do |lib|
      $:.unshift(File.expand_path(lib))
    end
  end

  def add_vendor_paths
    vendor_libs = Dir[LoadPath.vendor_path("/gems/*/lib")]
    add_paths(*vendor_libs)
    # put our lib at front of load path
    add_paths(LoadPath.lib_path)
  end

  def load(kind, basename)
    ext = File.extname(basename)
    if ext == ""
      ext = ".rb"
    end
    basename = File.basename(basename, ext)
    filename = LoadPath.send("#{kind}_path", "#{basename}#{ext}")
    Kernel.load filename
  end

  def require(kind, basename)
    Kernel.require LoadPath.send("#{kind}_path", basename.to_s)
  end

  def model(basename)
    load :model, basename
  end

  extend self
end

LoadPath.add_vendor_paths

if __FILE__ == $0
  p LoadPath.base_path
  p LoadPath.base_path("vendor")
  p LoadPath.var_path
  p LoadPath.model_path("tweet")

  LoadPath.def_path("models")
  p LoadPath.models_path
  p LoadPath.models_path("queue_report")

end
