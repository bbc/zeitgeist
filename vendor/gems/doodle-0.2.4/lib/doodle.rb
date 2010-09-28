# *doodle* is an eco-friendly metaprogramming framework that does not
# pollute core Ruby objects such as Object, Class and Module.
#
# While doodle itself is useful for defining classes, my main goal is to
# come up with a useful DSL notation for class definitions which can be
# reused in many contexts.
#
# Docs at http://doodle.rubyforge.org
#
# Requires Ruby 1.8.6 or higher
#
# Copyright (C) 2007-2009 by Sean O'Halpin
#
# 2007-11-24 first version
# 2008-04-18 0.0.12
# 2008-05-07 0.1.6
# 2008-05-12 0.1.7
# 2009-02-26 0.2.0
# 2009-03-11 0.2.3

if RUBY_VERSION < '1.8.6'
  raise Exception, "Sorry - doodle does not work with versions of Ruby below 1.8.6"
end

# set up load path
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# utils
require 'doodle/debug'
require 'doodle/ordered-hash'
require 'doodle/utils'
# doodle proper
require 'doodle/equality'
require 'doodle/comparable'
require 'doodle/exceptions'
require 'doodle/singleton'
require 'doodle/conversion'
require 'doodle/validation'
require 'doodle/deferred'
require 'doodle/info'
require 'doodle/smoke-and-mirrors'
require 'doodle/datatype-holder'
require 'doodle/to_hash'
require 'doodle/getter-setter'
require 'doodle/marshal'
require 'doodle/factory'
require 'doodle/inherit'
# now start assembling them together
require 'doodle/base'
require 'doodle/core'
require 'doodle/attribute'
require 'doodle/normalized_array'
require 'doodle/normalized_hash'
require 'doodle/collector'

class Doodle
  VERSION = "0.2.4"
end

############################################################
# and we're bootstrapped! :)
############################################################
