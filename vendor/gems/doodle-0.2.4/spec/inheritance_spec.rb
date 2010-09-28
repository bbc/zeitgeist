require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, "inheritance" do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle
        class << self
          has :cvar
        end
        has :ivar
      end
      class Bar < Foo
        class << self
          has :cvar2
        end
        has :ivar2
      end
    end

    it "should collect_inherited for instance" do
      foo = Foo.new(:ivar => "foo")
      foo.doodle.attributes.map{ |key, value| key}.should_be [:ivar] 
    end

    it "should collect inherited for singleton" do
      foo = Foo.new(:ivar => "foo")
      class << foo
        has :svar
      end
      foo.doodle.attributes.map{ |key, value| key}.should_be [:ivar, :svar] 
      foo.singleton_class.doodle.attributes.map{ |key, value| key}.should_be [:svar] 
    end

    it "should collect singleton class attributes for singleton" do
      foo = Foo.new(:ivar => "foo")
      class << foo
        has :svar
      end
      foo.singleton_class.respond_to?(:cvar).should_be true
      foo.doodle.attributes.map{ |key, value| key}.should_be [:ivar, :svar]
      # is this what I want? not sure
#      foo.class.singleton_class.should_be foo.singleton_class.superclass
#      foo.singleton_class.singleton_class                         # => #<Class:#<Class:#<Foo:0xb7bc8dd0>>>
      # and now it's false
      # all different in 1.9
#      foo.class.singleton_class.should_not == foo.singleton_class.superclass # => false
#      foo.singleton_class.respond_to?(:cvar).should_be true
    end
    
    it "should collect inherited for subclass singleton" do
      bar = Bar.new(:ivar => "foo", :ivar2 => "bar")
      class << bar
        has :svar2
      end
      bar.doodle.attributes.map{ |key, value| key}.should_be [:ivar, :ivar2, :svar2] 
      bar.singleton_class.doodle.attributes.map{ |key, value| key}.should_be [:svar2] 
    end
    
    it "should show instance attributes for class" do
      Foo.doodle.attributes.map{ |key, value| key}.should_be [:ivar] 
      Bar.doodle.attributes.map{ |key, value| key}.should_be [:ivar, :ivar2] 
    end

    it "should inherite class attributes for class" do
      Foo.doodle.class_attributes.map{ |key, value| key}.should_be [:cvar] 
      Bar.doodle.class_attributes.map{ |key, value| key}.should_be [:cvar, :cvar2] 
    end
    
    it "should not inherit class attributes via singleton_class" do
      Bar.singleton_class.doodle.attributes.map{ |key, value| key}.should_be [:cvar2] 
    end
  end
end
