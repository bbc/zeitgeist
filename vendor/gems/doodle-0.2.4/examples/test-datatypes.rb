$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'doodle/datatypes'
require 'doodle/utils'

class DateRange < Doodle
  doodle do
    date :start
    date :end do
      default { start + 1 }
    end
    version :version, :default => "0.0.1"
  end
end

#pp DateRange.instance_methods(false)

module UserTypes
  # include Doodle::DataTypes
  def printable(name, params = { }, &block)
    string(name, params, &block).instance_eval do
      must "not contain non-printing characters" do |s|
        s !~ /[\x00-\x1F]/
      end
    end
  end
  def name(name, params = { }, &block)
    printable(name, { :size => 1..255 }.merge(params), &block)
  end
end

class Person < Doodle
  doodle UserTypes do
    #    string :name, :max => 10
    name :name, :size => 3..10
    integer :age
    email :email, :default => ''
  end
end

pp try { DateRange "2007-01-18", :version => [0,0,9] }
pp try { Person 'Sean', '45', 'someone@example.com' }
pp try { Person 'Sean', '45' }
pp try { Person 'Sean', 'old' }
pp try { Person 'Sean', 45, 'this is not an email address' }
pp try { Person 'This name is too long', 45 }
pp try { Person 'Sean', 45, 42 }
pp try { Person 'A', 45 }
pp try { Person '123', 45 }
pp try { Person '', 45 }
#   pp try {
#     person = Person 'Sean', 45
#     person.name.silly
#   }
