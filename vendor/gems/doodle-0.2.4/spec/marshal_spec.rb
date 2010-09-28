require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/datatypes'

describe Doodle, 'datatypes' do
  temporary_constant :Foo, :Bar do

    it "should create an Integer datatype with integer" do
      class Foo < Doodle
        doodle do
          string :name
          integer :number
        end
      end
      foo = Foo("hello", 42)
      foo.marshal_dump.sort.map{ |k, v| [k.to_s, v] }.should_be [["@name", "hello"], ["@number", 42]]
      foo.marshal_load [["@name", "world"], ["@number", 99]]
      [foo.name, foo.number].should_be ["world", 99]
    end

  end
end
