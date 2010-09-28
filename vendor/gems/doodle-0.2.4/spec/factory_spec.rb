require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Factory, " as part of Doodle" do
  temporary_constant :Foo, :Bar do
    before(:each) do
      class Foo < Doodle
        has :var1
      end
      class Bar < Foo
        has :var2
      end
    end

    it 'should provide factory function' do
      proc {
        foo = Foo("abcd")
        foo.var1.should_be "abcd"
      }.should_not raise_error
    end

    it 'should inherit factory function' do
      proc {
        bar = Bar("abcd", 1234)
        bar.var1.should_be "abcd"
        bar.var2.should_be 1234
      }.should_not raise_error
    end
  end
end

describe Doodle::Factory, " included as module" do
  temporary_constant :Baz, :Qux, :MyDate, :AnotherDate do
    before(:each) do
      class Baz
        include Doodle::Core
        has :var1
      end
      class Qux < Baz
        has :var2
      end
      class MyDate < Date
        include Doodle::Factory
      end
      class AnotherDate < MyDate
      end
    end

    it 'should provide factory function' do
      proc {
        foo = Baz("abcd")
        foo.var1.should_be "abcd"
      }.should_not raise_error
    end

    it 'should inherit factory function' do
      proc {
        qux = Qux("abcd", 1234)
        qux.var1.should_be "abcd"
        qux.var2.should_be 1234
      }.should_not raise_error
    end

    it 'should be includeable in non-doodle classes' do
      proc {
        qux = MyDate(2008, 01, 01)
        qux.to_s.should_be "2008-01-01"
      }.should_not raise_error
    end

    # do I actually want this? should it be opt-in at each level?
    # it 'should be inheritable by non-doodle classes' do
    #   proc {
    #     qux = AnotherDate(2008, 01, 01)
    #     qux.to_s.should_be "2008-01-01"
    #     }.should_not raise_error
    # end

  end
end

describe Doodle::Factory, 'defined in a module' do
  temporary_constants :Foo, :Bar do
    before :each do
      module ::Foo
        class Bar < Doodle
          has :value
        end
      end
    end

    it 'should not define a global method' do
      expect_error {
        Bar(1)
      }
    end

    it 'should work when used inside a module definition' do
      expect_ok {
        module ::Foo
          Bar(2)
        end
      }
    end

    it 'should work as when used with Module::Name() form' do
      expect_ok {
        Foo::Bar(2)
      }
    end

    it 'should work as when used with Module.Name() form' do
      expect_ok {
        Foo.Bar(2)
      }
    end

  end
end
