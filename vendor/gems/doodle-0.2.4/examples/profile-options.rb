$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'

module CommandLine
  class Base < Doodle
    has :name
    singleton_class do
      has :doc
    end
    def to_s
      name
    end
  end
  class Command < Base
  end
  class KeyValue < Base
    # specify order (should I need to do this?)
    has :name
    has :value
    def to_s
      %[--#{name}="#{value}"]
    end
  end
  class Flag < Base
    def to_s
      %[--#{name}]
    end
  end
end

module Zenity
  include CommandLine
  class Entry < Flag
    # specifying name here has effect of re-ordering positional args
    doc "Display text entry dialogue"
    has :name, :default => :entry
  end
  class Text < KeyValue
    doc "Set the dialogue text"
    has :name, :default => :text
  end
  class EntryText < KeyValue
    doc "Set the entry text"
    has :name, :default => 'entry-text'
  end
  class HideText < KeyValue
    doc "Hide the entry text"
    has :name, :default => 'hide-text'
  end
end

include Zenity

1.upto(100) do
  cmd = [
         Command.new("zenity"),
         Entry.new(),
         #       KeyValue.new("text", "Enter name:"),
         #       KeyValue.new(:name => "text", :value => "Enter name:"),
         #       Text.new(:value => "Enter name:"),
         Text.new(:value => "Enter name:"),
         EntryText.new(:value => "Enter text"),
        ].join(' ')
  #puts cmd
end
#result = `#{cmd}`
#puts "result=#{result}"

