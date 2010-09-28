$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'
require 'pp'

class Foo < Doodle
end

methods = Foo.methods - Object.methods
instance_methods = Foo.instance_methods - Object.instance_methods
puts "class methods"
puts "  " + methods.sort.join("\n  ")
puts "instance_methods"
puts "  " + instance_methods.sort.join("\n  ")
puts "class methods only"
puts "  " + (methods - instance_methods).sort.join("\n  ")

