require File.dirname(__FILE__) + "/spec_helper.rb"

describe Doodle, "singletons" do
  temporary_constant :Foo do    
    it "should allow creating attributes on classes via inheritance" do
      class Foo < Doodle
        class << self
          has :c1
        end
      end
      Foo.doodle.attributes.should_be Doodle::OrderedHash.new
      Foo.singleton_class.doodle.attributes.should_not_be Doodle::OrderedHash.new
      Foo.singleton_class.doodle.attributes.map{ |name, attr| name }.should_be [:c1]
      Foo.c1 = 1
      Foo.c1.should_be 1
    end

    it "should allow creating attributes on classes via module inclusion" do
      class Foo
        include Doodle::Core
        class << self
          has :c2
        end
      end
      Foo.doodle.attributes.should_be Doodle::OrderedHash.new
      Foo.singleton_class.doodle.attributes.should_not_be Doodle::OrderedHash.new
      Foo.singleton_class.doodle.attributes.map{ |name, attr| name }.should_be [:c2]
      Foo.c2 = 1
      Foo.c2.should_be 1
    end

    it "should allow creating attributes on singletons via inheritance" do
      class Foo < Doodle
      end
      foo = Foo.new
      class << foo
        has :i1
      end
      foo.doodle.attributes.keys.should_be [:i1]
      foo.singleton_class.doodle.attributes.should_not_be Doodle::OrderedHash.new
      foo.singleton_class.doodle.attributes.map{ |name, attr| name }.should_be [:i1]
      foo.i1 = 1
      foo.i1.should_be 1
    end

    it "should allow creating attributes on a singleton's singleton via module inclusion" do
      class Foo
        include Doodle::Core
      end
      foo = Foo.new
      class << foo
        class << self
          has :i2
        end
      end
      foo.doodle.attributes.should_be Doodle::OrderedHash.new
      foo.singleton_class.singleton_class.doodle.attributes.should_not_be Doodle::OrderedHash.new
      foo.singleton_class.singleton_class.doodle.attributes.map{ |name, attr| name }.should_be [:i2]
      foo.singleton_class.i2 = 1
      foo.singleton_class.i2.should_be 1
    end
  end
end
