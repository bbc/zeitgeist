$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'
require 'doodle/utils'
require 'pp'

class Foo < Doodle
  has :name, :kind => String
end

params = {
  :name => 1,
  :extra => 42
}

rv = Doodle::Utils.try {
  foo = Foo(params)
}
pp rv

rv = Doodle::Utils.try {
  Doodle.raise_exception_on_error = false
  foo = Foo(params)
  foo.doodle.errors
}
pp rv
