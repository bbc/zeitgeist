require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'defaults which have not been set' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :baz
        has :start, :default => 1
      end
    end

    it 'should raise Doodle::ValidationError if required value not set' do
      proc { Foo.new }.should raise_error(Doodle::ValidationError)
    end
  end
end

