require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'kind' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :var1, :kind => [String, Symbol]
      end
    end
    
    it 'should allow multiple kinds' do
      proc { Foo 'hi' }.should_not raise_error
      proc { Foo :hi }.should_not raise_error
      proc { Foo 1 }.should raise_error(Doodle::ValidationError)
    end
  end
end
