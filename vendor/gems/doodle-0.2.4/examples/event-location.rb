$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'date'
require 'doodle'
require "yaml"
require "pp"

class Location < Doodle
  has :name, :kind => String
  has :events, :init => [], :collect => :Event
end

class Event
  # or if you want to inherit from another class
  include Doodle::Core
  include Doodle::Factory

  has :name, :kind => String
  has :date do
    kind Date
    default { Date.today }
    must 'be >= today' do |value|
      value >= Date.today
    end
    from String do |s|
      Date.parse(s)
    end
  end
  has :locations, :collect => {:place => :Location}
end

event = Event "Festival" do
  date '2018-04-01'
  place "The muddy field"
  place "Beer tent" do
    event "Drinking"
  end
end

str = event.to_yaml
puts str
loaded_event = YAML::load(str)
pp loaded_event

str =<<EOS
--- !ruby/object:Event
name: Glastonbury
date: 2000-07-01
EOS

def capture(&block)
  begin
    block.call
  rescue Exception => e
    e
  end
end

res = capture {
  event = YAML::load(str).validate! # will raise Doodle::ValidationError
}
pp res

hash_data = {
  :name => "Festival",
  :date => '2010-04-01',
  :locations =>
  [
   {
     :events => [],
     :name => "The muddy field",
   },
   {
     :name => "Beer tent",
     :events =>
     [
      {
        :name => "Drinking",
        :locations => [],
      }
     ]
   }
  ]
}

pp hash_data

e = Event(hash_data)
pp e

__END__
--- !ruby/object:Event
date: 2000-04-01
locations:
- !ruby/object:Location
  events: []

  name: The muddy field
- !ruby/object:Location
  events:
  - !ruby/object:Event
    locations: []

    name: Drinking
  name: Beer tent
name: Festival
