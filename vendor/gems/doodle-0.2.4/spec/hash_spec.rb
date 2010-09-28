require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'instances as hash keys' do
  temporary_constants :Key, :Other do
    before :each do
      #: definition
      class ::Key < Doodle
        has :value
      end
      class ::Other < Doodle
        has :value
      end
    end

    it 'should treat as identical keys doodles which are equal' do
      h = {
        Key(1) => 1,
        Key(1) => 2
      }
      h.should_be({ Key(1) => 2 })
    end

    it 'should not treat as identical keys doodles which have equal values but different classes' do
      h = {
        Key(1) => 1,
        Other(1) => 2
      }
      h.should_be({ Key(1) => 1, Other(1) => 2 })
    end
  end
end
