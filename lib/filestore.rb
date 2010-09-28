# Simple file based store with hash-like interface

require File.join(File.dirname(__FILE__), '../lib/load_paths')
require 'doodle'
require 'fileutils'
require 'json'

class FileStore < Doodle
  include Enumerable

  has :group, :kind => String do
    from Object do |o|
      o.to_s
    end
  end

  has :base_dir do
    default { File.expand_path(File.join(File.dirname(__FILE__), '..')) }
  end

  has :public_dir do
    default { File.join(base_dir, 'public') }
  end

  def fullpath(*args)
    File.join(public_dir, group, *args)
  end

  def put(key, data)
    FileUtils.mkdir_p(fullpath)
    # JSON requires object is either Array or Map (Hash)
    # using map allows us to add metadata
    write(fullpath(key), { :data => data }.to_json)
  end

  alias []= put

  def get(key)
    # JSON requires object is either Array or Map (Hash)
    path = fullpath(key)
    if File.exist?(path)
      res = JSON.parse(File.read(path))
      if res.key?("data")
        res["data"]
      else
        res
      end
    else
      nil
    end
  end

  alias [] get

  def values
    keys.map{ |key| get(key) }
  end

  def to_a
    keys.map{ |key| [key, get(key)] }
  end

  def each(&block)
    to_a.each(&block)
  end

  def keys
    filelist.map{ |x| File.basename(x)}
  end

  def filelist
    Dir["#{fullpath}/*"]
  end

  def write(file, data)
    File.open(file, "w") do |file|
      file.write(data)
    end
  end

  def read(file)
    File.read(file, "w")
  end

  def delete(key)
    FileUtils.safe_unlink(fullpath(key))
  end
end
