require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/datatypes'

describe Doodle, 'datatypes' do
  temporary_constant :Foo, :Bar do

    it "should create an Integer datatype with integer" do
      class Foo < Doodle
        doodle do
          integer :number
        end
      end
      Foo.doodle.attributes[:number].kind.should_be [Integer]
      foo = Foo("42")
      foo.number.should_be 42
      foo = Foo(99.9)
      foo.number.should_be 99
    end

    it "should validate against an array of values" do
      class Foo < Doodle
        doodle do
          integer :number, :values => [42, 99]
        end
      end
      foo = Foo(42)
      proc { foo.number = 1 }.should raise_error(Doodle::ValidationError)
    end

    it "should validate against a minumum and maximum" do
      class Foo < Doodle
        doodle do
          integer :number, :min => 41, :max => 42
        end
      end
      foo = Foo(42)
      proc { foo.number = 40 }.should raise_error(Doodle::ValidationError)
      proc { foo.number = 43 }.should raise_error(Doodle::ValidationError)
      proc { foo.number = 42 }.should_not raise_error
    end

    it "should validate against a range of values" do
      class Foo < Doodle
        doodle do
          integer :number, :values => 42..99
        end
      end
      foo = Foo(42)
      proc { foo.number = 1 }.should raise_error(Doodle::ValidationError)
    end

    it "should create a boolean datatype with boolean" do
      class Foo < Doodle
        doodle do
          boolean :flag
        end
      end
      Foo.doodle.attributes[:flag].kind.should_be []
      foo = Foo(1)
      foo.flag.should_be true
      foo.flag = "off"
      foo.flag.should_be false
      foo.flag = "on"
      foo.flag.should_be true
      foo.flag = nil
      foo.flag.should_be false
      foo.flag = "something else"
      foo.flag.should_be true
      foo.flag = ""
      foo.flag.should_be false
    end

    it "should create a String attribute with string" do
      class Foo < Doodle
        doodle do
          string :name
        end
      end
      Foo.doodle.attributes[:name].kind.should_be [String]
    end

    it "should convert an integer into a String with string" do
      class Foo < Doodle
        doodle do
          string :name
        end
      end
      Foo(1).name.should_be "1"
    end

    it "should convert a symbol into a String with string" do
      class Foo < Doodle
        doodle do
          string :name
        end
      end
      Foo(:sean).name.should_be "sean"
    end

    it "should validate a string attribute with match" do
      class Foo < Doodle
        doodle do
          string :name, :match => /^S/
        end
      end
      proc { Foo("Sean") }.should_not raise_error
      proc { Foo("Jim") }.should raise_error(Doodle::ValidationError)
    end

    it "should validate a string attribute size" do
      class Foo < Doodle
        doodle do
          string :name, :size => 1..3
        end
      end
      proc { Foo("Jim") }.should_not raise_error
      proc { Foo("Sean") }.should raise_error(Doodle::ValidationError)
      proc { Foo("S") }.should_not raise_error
      proc { Foo("") }.should raise_error(Doodle::ValidationError)
    end

    it "should validate a string attribute with min and max" do
      class Foo < Doodle
        doodle do
          string :name, :min => 1, :max => 3
        end
      end
      proc { Foo("Jim") }.should_not raise_error
      proc { Foo("Sean") }.should raise_error(Doodle::ValidationError)
      proc { Foo("S") }.should_not raise_error
      proc { Foo("") }.should raise_error(Doodle::ValidationError)
    end

    it "should create a Symbol attribute with symbol" do
      class Foo < Doodle
        doodle do
          symbol :name
        end
      end
      Foo.doodle.attributes[:name].kind.should_be [Symbol]
      foo = Foo("Sean")
      foo.name.should_be :Sean
      proc { Foo(1) }.should raise_error(Doodle::ValidationError)
    end

    it "should create a URI attribute with uri" do
      class Foo < Doodle
        doodle do
          uri :address
        end
      end
      Foo.doodle.attributes[:address].kind.should_be [URI]
      foo = Foo("http://www.example.com")
      foo.address.kind_of?(URI).should_be true
    end

    it "should create an email attribute with email" do
      class Foo < Doodle
        doodle do
          email :address
        end
      end
      Foo.doodle.attributes[:address].kind.should_be [String]
      proc {  Foo("doodle@rubyforge.org") }.should_not raise_error
      proc {  Foo("doodle") }.should raise_error(Doodle::ValidationError)
      proc {  Foo("Sean.O'Halpin@example.org") }.should_not raise_error
    end

    it "should create a date attribute with date" do
      class Foo < Doodle
        doodle do
          date :start
        end
      end
      Foo.doodle.attributes[:start].kind.should_be [Date]
      ref_date = Date.parse('1 Jan 2009')

      # from Date
      foo = Foo(ref_date)
      foo.start.kind_of?(Date).should_be true
      foo.start.should_be ref_date

      # from String
      foo = Foo("2009-01-01")
      foo.start.kind_of?(Date).should_be true
      foo.start.should_be ref_date

      # from Array
      foo = Foo([2009, 01, 01])
      foo.start.kind_of?(Date).should_be true
      foo.start.should_be ref_date

      # from Julian date
      foo = Foo(ref_date.jd)
      foo.start.kind_of?(Date).should_be true
      foo.start.should_be ref_date

    end

    it "should create a date attribute with date" do
      class Foo < Doodle
        doodle do
          time :start
        end
      end
      Foo.doodle.attributes[:start].kind.should_be [Time]
      ref_date = Time.parse('1 Jan 2009')

      # from Date
      foo = Foo(ref_date)
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from String
      foo = Foo("2009-01-01")
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from Array
      foo = Foo([2009, 01, 01])
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from Julian date
      foo = Foo(ref_date.to_i)
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

    end

    it "should create a date attribute with date" do
      class Foo < Doodle
        doodle do
          time :start, :timezone => :local
        end
      end
      Foo.doodle.attributes[:start].kind.should_be [Time]
      ref_date = Time.parse('1 Jan 2009')

      # from Date
      foo = Foo(ref_date)
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from String
      foo = Foo("2009-01-01")
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from Array
      foo = Foo([2009, 01, 01])
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      # from Julian date
      foo = Foo(ref_date.to_i)
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

    end

    it "should create a utc date attribute with utc" do
      class Foo < Doodle
        doodle do
          utc :start
        end
      end
      Foo.doodle.attributes[:start].kind.should_be [Time]
      ref_date = Time.parse('1963-01-10T10:30Z')

      # from String
      foo = Foo("1963-01-10T10:30")
      foo.start.kind_of?(Time).should_be true
      foo.start.should_be ref_date

      foo = Foo("1963-01-10T10:30Z")
      foo.start.should_be ref_date

      foo = Foo("1963-01-10")
      foo.start.should_be Time.parse('1963-01-10T00:00Z')

      proc { Foo("1963-01-10BST") }.should raise_error(Doodle::ConversionError)

    end

    it "should create a utc date attribute with utc" do
      class Foo < Doodle
        doodle do
          version :version
        end
      end
      Foo.doodle.attributes[:version].kind.should_be [String]
      foo = Foo("1.2.3")
      foo.version.should_be "1.2.3"
      foo = Foo([1, 2, 3])
      foo.version.should_be "1.2.3"
    end

    it "should create a list attribute with list" do
      class ::Foo < Doodle
        doodle do
          string :name
        end
      end
      class ::Bar < Doodle
        doodle do
          list ::Foo
        end
      end
      ::Bar.doodle.attributes[:foos].kind.should_be []
      bar = Bar do
        foo "hello"
        foo "world"
      end
      bar.foos.should_be [Foo("hello"), Foo("world")]
      bar.foos.map{ |f| f.name }.should_be ["hello", "world"]
    end

    it "should create a list attribute with list" do
      class ::Foo < Doodle
        doodle do
          string :name
        end
      end
      class ::Bar < Doodle
        doodle do
          dictionary ::Foo, :key => :name
        end
      end
      Bar.doodle.attributes[:foos].kind.should_be []
      bar = Bar do
        foo "hello"
        foo "world"
      end
      bar.foos.should_be( { "hello" => Foo("hello"), "world" => Foo("world") } )
    end

    it "should allow all doodle directives inside doodle block" do
      class ::Foo < Doodle
        doodle do
          string :name
          has :key
          from String do |s|
            ::Foo.new(*s.split(";"))
          end
          must "have key != name" do
            name != key
          end
          arg_order :name, :key
          doc "Hello"
        end
      end
      foo = Foo.from("hello;world")
      foo.validate!
    end

  end
end
