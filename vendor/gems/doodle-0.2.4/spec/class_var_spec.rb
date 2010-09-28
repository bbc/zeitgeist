require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'class attributes:' do
  temporary_constant :Foo, :Bar do
    before :each do
      class Foo < Doodle
        has :ivar
        class << self
          has :cvar, :kind => Integer, :init => 1
        end
      end
      class Bar < Doodle
      end
    end

    it 'should be possible to set a class var without setting an instance var' do
      proc { Foo.cvar = 42 }.should_not raise_error
      Foo.cvar.should == 42
    end

    it 'should be possible to set an instance variable without setting a class var' do
      proc { Foo.new :ivar => 42 }.should_not raise_error
    end
    
    it 'should be possible to set a class variable without setting an newly added instance var' do
      proc {
        foo = Bar.new
        class << Bar
          has :cvar, :init => 43
        end
        class Bar < Doodle
          has :ivar
        end
        Bar.cvar = 44
      }.should_not raise_error
    end

    it 'should be possible to set a singleton variable without setting an instance var' do
      proc {
        class Bar < Doodle
          has :ivar
        end
        foo = Bar.new :ivar => 42
        class << foo
          has :svar, :init => 43
        end
        foo.svar = 44
      }.should_not raise_error
    end

    it 'should not be possible to set a singleton variable without setting a newly added instance var' do
      proc {
        foo = Bar.new
        class << foo
          has :svar, :init => 43
        end
        class Bar < Doodle
          has :ivar
        end
        foo.svar = 44
      }.should raise_error(Doodle::ValidationError)
    end
    
    it 'should be possible to set a singleton variable along with setting a newly added instance var using defer_validation' do
      proc {
        foo = Bar.new
        class << foo
          has :svar, :init => 43
        end
        class Bar < Doodle
          has :ivar
        end
        foo.doodle.defer_validation do
          svar 44
          ivar 42
        end
      }.should_not raise_error
    end

    it 'should validate class var' do
      proc { Foo.cvar = "Hello" }.should raise_error(Doodle::ValidationError)
    end

    it 'should be possible to read initialized class var' do
      #pending 'getting this working' do
      proc { Foo.cvar == 1 }.should_not raise_error
      #end
    end
  end
end
