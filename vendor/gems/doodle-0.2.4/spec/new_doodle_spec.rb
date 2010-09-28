require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'simple' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :var1
        has :var2
        has :var3
      end
    end
    it 'should be allow instantiation' do
      foo = Foo.new 1, 2, 3
      foo.var1.should_be 1
      foo.var2.should_be 2
      foo.var3.should_be 3
    end
  end
end
