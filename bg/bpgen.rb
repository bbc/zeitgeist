#!/usr/bin/env ruby
#
# usage: ruby bg/bpgen.rb <config_dir>/<group>.yml
# e.g.
#
#     ruby bg/bpgen.rb smq_config/bbc_links.yml > tmp/bbc_links.pill
#     sudo bluepill load pill/bbc_links.pill
#
# Note: can't use bash <(cmd) construct with bluepill - wants a real file :/
#
# This scripts generates a bluepill config as specified in the given
# YAML config file.
#
# Note: This is pretty specific to the Zeitgeist app but can be used
# with other commands.
#
## requires
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/load_paths'))
require 'shellwords'
require 'config'
require 'quotes'
require 'yaml'
require 'json'

include Quotes

## load config and template
config_filename = ARGV[0]
template_filename = ARGV[1] || "smq_config/smq_bluepill_template.erb"

config = ConfigHelper.load_from_path(LoadPath.base_path(config_filename))
template = File.read(LoadPath.base_path(template_filename))
dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

## set up dirs and env
pid_dir = config[:tempdir] || "/tmp"
log_dir = config[:logdir] || "/tmp"

# don't set env variables! causes a subshell to be started
# env = { "RUBYOPT" => "-rubygems" }

if ENV["http_proxy"]
  env = env.merge({:http_proxy => ENV["http_proxy"]})
end

processes = []

## set up processes
config[:processes].each do |process|
  name = process[:name]
  cmd  = process[:cmd]
  if cmd.kind_of?(Hash)
    if smq = cmd[:smq]
      cmd = "ruby scripts/smq #{smq}"
    else
      raise ArgumentError, "Unknown cmd key: #{cmd}"
    end
  end

  # don't construct env string - causes subshell which prevents bluepill from being able to quit the process
  # this is fixed in my version of bluepill but we won't be using that so...
  # this is only used for requiring rubygems so we do that in the script files themselves
  # ## construct env string
  # if process.key?(:env)
  #   env = env.merge(process[:env])
  # end
  # env_str = env.map{ |k, v| %[#{k}="#{Shellwords.escape(v)}"]}.join(' ')

  ## construct args
  if process.key?(:args)
    args = process[:args]
    if not args.key?(:name)
      args[:name] = name
    end
    args_kv = args.map{ |k, v|
      "--#{k} #{Shellwords.escape(v.nil? ? 'null' : v)}"
    }
  else
    args_kv = []
  end

  ## JSON params
  if process.key?(:params)
    params_str = "--params #{q process[:params].to_json}"
  else
    params_str = ""
  end

  ## complete command string
  # note: don't include env_str - see note above
  cmd_string = ["/usr/bin/env", cmd, args_kv, params_str].join(' ')

  ## start up process `count` times
  count = process[:count] || 1
  if count > 1
    1.upto(count) do |i|
      name_i = "#{name}_%02d" % i
      processes << { :name => name_i, :cmd => cmd_string, :dir => dir, :log_dir => log_dir, :pid_dir => pid_dir }
    end
  else
    processes << { :name => name, :cmd => cmd_string, :dir => dir, :log_dir => log_dir, :pid_dir => pid_dir }
  end
end

config[:processes] = processes

## generate bluepill config
puts ErbBinding.erb(template, config)
