require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, "definitions within rspec" do
  temporary_constant :Foo1 do
    before :each do
      class Foo1 < Doodle
        has :name
      end
    end
    it 'should define a constructor function' do
      no_error { foo = Foo1("Bar") }
    end
  end
end

describe Doodle, "definitions at top level" do
  temporary_constant :Foo2 do
    before :each do
      class ::Object
        class Foo2 < Doodle
          has :name
        end
      end
    end
    it 'should define a constructor function' do
      no_error { foo = Foo2("Bar") }
    end
  end
end

describe Doodle, "definitions in modules" do
  temporary_constant :Foo3, :Bar3 do
    before :each do
      module ::Bar3
        class Foo3 < Doodle
          has :name
        end
      end
    end
    it 'should define a constructor function' do
      no_error { foo = ::Bar3.Foo3("Bar") }
    end
  end
end

describe Doodle, "definitions in module_eval" do
  temporary_constant :Foo4, :Bar4 do
    before :each do
      module ::Bar4
      end
      Bar4.module_eval do
        class Foo4 < Doodle
          has :name
        end
      end
    end
    it 'should define a constructor function' do
      no_error { foo = Bar4.send(:Foo4, "Bar") }
    end
    it 'should define a public constructor function' do
      pending "getting to work with 1.8.6"
      no_error { foo = Bar4.Foo4("Bar") }
      no_error { foo = Bar4::Foo4("Bar") }
    end
  end
end

