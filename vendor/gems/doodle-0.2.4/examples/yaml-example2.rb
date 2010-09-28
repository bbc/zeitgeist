$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'yaml'
require 'doodle'
require 'pp'

class AddressLine < Doodle
  has :text, :kind => String
end

class Person < Doodle
  has :name, :kind => String
  has :address, :collect => { :line => AddressLine }
end

yaml = %[
---
:address:
- Henry Wood House
- London
:name: Sean
]

person = Person(YAML.load(yaml))
pp person
yaml = person.to_yaml
puts yaml

yaml = %[
--- !ruby/object:Person
address:
- !ruby/object:AddressLine
  text: Henry Wood House
- !ruby/object:AddressLine
  text: London
name: Sean
]
person = YAML.load(yaml).validate!
pp person

