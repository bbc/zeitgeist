require File.dirname(__FILE__) + '/spec_helper.rb'

# see bugs:core-28
describe Doodle::DeferredBlock do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :first_name
        has :last_name
        has :full_name do
          init { first_name + " " + last_name} # would probably use default in practice
        end
      end
    end

    it 'should set init values from attributes given in keyword arguments' do
      foo = nil
      proc {
        foo = Foo :first_name => "Roly", :last_name => "Poly"
      }.should_not raise_error

      foo.full_name.should_be "Roly Poly"
    end

    it 'should set init values from attributes given in block arguments' do
      foo = nil
      proc {  foo = Foo do
          first_name "Roly"
          last_name "Poly"
        end
      }.should_not raise_error
      foo.full_name.should_be "Roly Poly"
    end
  end
end
