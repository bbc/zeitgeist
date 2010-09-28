require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'readonly attributes' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :ivar1, :readonly => true
      end
    end

    it 'should allow setting readonly attribute during initialization' do
      proc { Foo.new(:ivar1 => "hello") }.should_not raise_error
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo.new(:ivar1 => "hello")
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo do
        ivar1 "hello"
      end
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

  end
end

describe 'Doodle', 'readonly attributes #2' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :ivar1 do
          readonly true
        end
      end
    end

    it 'should allow setting readonly attribute during initialization' do
      proc { Foo.new(:ivar1 => "hello") }.should_not raise_error
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo.new(:ivar1 => "hello")
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo do
        ivar1 "hello"
      end
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

    # core-30: BUG: can set readonly attribute with deferred validation block - no error on exit from block
    # but does this matter?
    it 'should not allow setting readonly attribute after initialization' do
      pending
      foo = Foo do
        ivar1 "hello"
      end
      foo.ivar1.should_be "hello"
      foo.doodle.defer_validation do
        ivar1 "world"
      end
      foo.ivar1.should_be "hello"
    end

  end
end

