require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'inheriting validations' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :var1, :kind => Integer
        has :var2, :kind => Integer, :default => 1
        must 'have var1 != var2' do
          var1 != var2
        end
      end
    end

    it 'should not duplicate validations when accessing them!' do
      foo = Foo 2
      foo.doodle.validations.size.should_be 1
      foo.doodle.validations.size.should_be 1
    end
  end
end

describe 'Doodle', 'loading good data from yaml' do
  temporary_constant :Foo do
    before :each do
      class ::Foo < Doodle
        has :date, :kind => Date do
          from String do |s|
            Date.parse(s)
          end
        end
      end
      @str = %[
      --- !ruby/object:Foo
      date: "2000-7-01"
      ]

    end

    it 'should succeed without validation' do
      proc { foo = YAML::load(@str)}.should_not raise_error
    end

    it 'should validate ok' do
      proc { foo = YAML::load(@str).validate! }.should_not raise_error
    end

    it 'should apply conversions' do
      foo = YAML::load(@str).validate!
      foo.date.should_be Date.new(2000, 7, 1)
      foo.date.class.should_be Date
    end
  end
end

describe 'Doodle', 'loading bad data from yaml' do
  temporary_constant :Foo do
    before :each do
      class ::Foo < Doodle
        has :date, :kind => Date do
          from String do |s|
            Date.parse(s)
          end
        end
      end
      @str = %[
      --- !ruby/object:Foo
      date: "2000"
      ]
    end

    it 'should succeed without validation' do
      proc { foo = YAML::load(@str)}.should_not raise_error
    end

    it 'should fail with ConversionError when it cannot convert' do
      proc { foo = YAML::load(@str).validate! }.should raise_error(Doodle::ConversionError)
    end
  end
end

describe 'Doodle', 'loading bad data from yaml with default defined' do
  temporary_constant :Foo do
    before :each do
      class ::Foo < Doodle
        has :date, :kind => Date do
          default Date.today
          from String do |s|
            Date.parse(s)
          end
        end
      end
      @str = %[
      --- !ruby/object:Foo
      date: "2000"
      ]
    end

    it 'should succeed without validation' do
      proc { foo = YAML::load(@str)}.should_not raise_error
    end

    it 'should fail with ConversionError when it cannot convert' do
      proc { foo = YAML::load(@str).validate! }.should raise_error(Doodle::ConversionError)
    end
  end
end

describe Doodle, 'class attributes:' do
  temporary_constant :Foo do
    before :each do
      class ::Foo < Doodle
        has :ivar
        class << self
          has :cvar
        end
      end
    end

    it 'should be possible to set a class var without setting an instance var' do
      proc { Foo.cvar = 42 }.should_not raise_error
    end
  end
end

describe Doodle, 'initializing from hashes and yaml' do
  temporary_constants :AddressLine, :Person do
    before :each do
      class ::AddressLine < Doodle
        has :text, :kind => String
      end

      class ::Person < Doodle
        has :name, :kind => String
        has :address, :collect => { :line => ::AddressLine }
      end
    end

    # TODO: this is a bit of a mess - split into separate specs and clarify what I'm expecting
    it 'should validate output from to_yaml' do

      source_yaml = %[
---
:address:
- Henry Wood House
- London
:name: Sean
]

      person = Person(YAML.load(source_yaml))
      yaml = person.to_yaml
      # be careful here - Ruby yaml is finicky (spaces after class names)
      yaml = yaml.gsub(/\s*\n/m, "\n")
      #       yaml.should_be %[--- !ruby/object:Person
      # address:
      # - !ruby/object:AddressLine
      #   text: Henry Wood House
      # - !ruby/object:AddressLine
      #   text: London
      # name: Sean
      # ]
      loaded = YAML::load(source_yaml)
      loaded[:name].should_be person.name
      loaded[:address].should_be person.address.map{|x| x.text}
      # want to compare yaml output with this but different order for every version of ruby, jruby, etc.
      # "--- !ruby/object:Person\naddress:\n- !ruby/object:AddressLine\n  text: Henry Wood House\n- !ruby/object:AddressLine\n  text: London\nname: Sean\n"
      person = YAML.load(yaml)
      proc { person.validate! }.should_not raise_error
      person.address.all?{ |x| x.kind_of?(AddressLine) }.should_be true

    end
  end
end

describe 'Doodle', 'hiding @__doodle__' do
  temporary_constant :Foo, :Bar, :DString, :DHash, :DArray do
    before :each do
      class ::Foo < Doodle
        has :var1, :kind => Integer
      end
      class ::Bar
        include Doodle::Core
        has :var2, :kind => Integer
      end
      class ::DString < String
        include Doodle::Core
      end
      class ::DHash < Hash
        include Doodle::Core
      end
      class ::DArray < Array
        include Doodle::Core
      end
    end

    it 'should not reveal @__doodle__ in inspect string' do
      foo = Foo 2
      foo.inspect.should_not =~ /@__doodle__/
    end
    it 'should not include @__doodle__ in instance_variables' do
      foo = Foo 2
      foo.instance_variables.size.should_be 1
      foo.instance_variables.first.should =~ /^@var1$/
    end
    it 'should not reveal @__doodle__ in inspect string' do
      foo = Bar 2
      foo.inspect.should_not =~ /@__doodle__/
    end
    it 'should not include @__doodle__ in instance_variables' do
      foo = Bar 2
      foo.instance_variables.size.should_be 1
      foo.instance_variables.first.should =~ /^@var2$/
    end
    it 'should correctly inspect when using included module' do
      foo = Bar 2
      foo.inspect.should =~ /#<Bar:0x[a-z0-9]+ @var2=2>/
    end
    it 'should correctly inspect string' do
      foo = DString("Hello")
      foo.inspect.should_be '"Hello"'
    end
    it 'should correctly inspect hash' do
      foo = DHash.new(2)
      foo[:a] = 1
      foo.inspect.should_be '{:a=>1}'
      foo[:b].should_be 2
    end
    it 'should correctly inspect array' do
      foo = DArray(3, 2)
      foo.inspect.should_be '[2, 2, 2]'
    end
  end
end

describe 'Doodle', 'initalizing class level collectors' do
  temporary_constant :Menu, :KeyedMenu, :Item, :SubMenu do
    before :each do
      class ::Item < Doodle
        has :title
      end
      class ::Menu < Doodle
        class << self
          has :items, :collect => Item
        end
      end
      class ::KeyedMenu < Doodle
        class << self
          has :items, :collect => Item, :key => :title
        end
      end
    end

    it 'should collect first item specified in appendable collector' do
      class SubMenu < Menu
        item "Item 1"
      end
      SubMenu.items[0].title.should_be "Item 1"
    end

    it 'should collect all items specified in appendable collector' do
      class SubMenu < Menu
        item "New Item 1"
        item "New Item 2"
        item "New Item 3"
      end
      SubMenu.items[0].title.should_be "New Item 1"
      SubMenu.items[2].title.should_be "New Item 3"
      SubMenu.items.size.should_be 3
    end

    it 'should collect first item specified in keyed collector' do
      class SubMenu < KeyedMenu
        item "Item 1"
      end
      SubMenu.items["Item 1"].title.should_be "Item 1"
    end

    it 'should collect all items specified in keyed collector' do
      class SubMenu < KeyedMenu
        item "New Item 1"
        item "New Item 2"
        item "New Item 3"
      end
      SubMenu.items["New Item 1"].title.should_be "New Item 1"
      SubMenu.items["New Item 3"].title.should_be "New Item 3"
      SubMenu.items.size.should_be 3
    end

    it 'should collect all items specified in keyed collector in order' do
      class SubMenu < KeyedMenu
        item "New Item 1"
        item "New Item 2"
        item "New Item 3"
      end
      SubMenu.items.to_a[0][0].should_be "New Item 1"
      SubMenu.items.to_a[2][0].should_be "New Item 3"
      SubMenu.items.size.should_be 3
    end
  end
end

describe 'Doodle', 'validating required attributes after default attributes' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :v1, :default => 1
        has :v2
      end
    end

    it 'should validate required attribute after an attribute with default defined' do
      proc { Foo.new }.should raise_error(Doodle::ValidationError)
    end

    it 'should validate required attribute after an attribute with default defined specified #1' do
      proc { Foo.new(1) }.should raise_error(Doodle::ValidationError)
    end

    it 'should validate required attribute after an attribute with default defined specified #2' do
      proc { Foo.new(:v1 => 1) }.should raise_error(Doodle::ValidationError)
    end

    it 'should validate specified required attribute after an attribute with default defined not specified' do
      proc { Foo.new(:v2 => 2) }.should_not raise_error
    end
  end
end

describe Doodle, 'if default specified before required attributes, they are ignored if defined in block' do
  temporary_constant :Address do
    before :each do
      class Address < Doodle
        has :where, :default => "home"
        has :city
      end
    end

    it 'should raise an error that required attributes have not been set' do
      proc {
        Address do
          city "London"
        end
      }.should_not raise_error
    end

    it 'should define required attributes' do
      a = Address do
        city "London"
      end
      a.city.should_be "London"
    end
  end

end

describe Doodle, 'conversion from Proc' do
  it 'should not raise an error in conversion if kind is Proc' do
    pending 'implementation of spec'
  end

end
