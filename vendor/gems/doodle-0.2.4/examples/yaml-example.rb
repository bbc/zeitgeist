$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'
require 'doodle/utils'
require 'yaml'

class Foo < Doodle
  has :name, :kind => String
end

# load valid data
str = %[
--- !ruby/object:Foo
name: Stimpy
]
bar = nil
rv = try do
  bar = YAML::load(str).validate!
end
rv # => #<Foo:0xb7b02cc0 @name="Stimpy">
bar # => #<Foo:0xb7b02cc0 @name="Stimpy">

str = %[
--- !ruby/object:Foo
name: 1
]

# load invalid data
baz = nil
rv = try do
  baz = YAML::load(str).validate!
end
rv # => #<Doodle::ValidationError: name must be String - got Fixnum(1)>
baz # => nil

# load from hash
str = %[
name: Qux
]

qux = Foo(YAML::load(str)) # => #<Foo:0xb7aff520 @name="Qux">
