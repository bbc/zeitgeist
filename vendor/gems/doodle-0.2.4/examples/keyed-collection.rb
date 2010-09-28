$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'date'
require "yaml"
require "pp"

require 'doodle'
require 'doodle/utils'

class Location < Doodle
  has :name, :kind => String
  has :events, :collect => :Event, :key => :name
end

class Event #< Doodle
  # or if you want to inherit from another class
  include Doodle::Core

  has :name, :kind => String
  has :date, :kind => Date do
    default { Date.today }
    from String do |s|
      Date.parse(s)
    end
  end
  has :locations, :collect => {:place => :Location}, :key => :name
end  

event = Event "Festival" do
  date '2018-04-01'
  place "The muddy field"
  place "Beer tent" do
    event "Drinking"
    event "Dancing"
  end
end

yaml = event.to_yaml
puts yaml
# >> --- !ruby/object:Event 
# >> date: 2018-04-01
# >> locations: 
# >>   Beer tent: !ruby/object:Location 
# >>     events: 
# >>       Drinking: !ruby/object:Event 
# >>         locations: {}
# >> 
# >>         name: Drinking
# >>       Dancing: !ruby/object:Event 
# >>         locations: {}
# >> 
# >>         name: Dancing
# >>     name: Beer tent
# >>   The muddy field: !ruby/object:Location 
# >>     events: {}
# >> 
# >>     name: The muddy field
# >> name: Festival
event2 = YAML::load(yaml).validate!
p event == event2
