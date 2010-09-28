require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'multiple collector' do
  temporary_constants :Text, :Item, :List do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::Text < Doodle
        has :body, :kind => String
      end
      class ::List < Doodle
        has :items, :collect => [Item, Text]
      end
    end

    it 'should accept convertible values in collector' do
      list = nil
      no_error {
        list = List do
          item "Hello"
          text "World"
        end
      }
      list.items.size.should_be 2
      list.items[0].should_be Item("Hello")
      list.items[1].should_be Text("World")
    end
  end
end

describe Doodle, 'multiple collector' do
  temporary_constants :Text, :Item, :List do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::Text < Doodle
        has :body, :kind => String
      end
      class ::List < Doodle
        has :items, :collect => [ { :foo => Item }, { :bar => Text } ]
      end
    end

    it 'should accept convertible values in collector using specified collector methods' do
      list = nil
      no_error {
        list = List do
          foo "Hello"
          bar "World"
        end
      }
      list.items.size.should_be 2
      list.items[0].should_be Item("Hello")
      list.items[1].should_be Text("World")
    end
  end
end

describe Doodle, 'multiple collector' do
  temporary_constants :Text, :Item, :List do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::Text < Doodle
        has :body, :kind => String
      end
      class ::List < Doodle
        has :items, :collect => { :foo => Item, :bar => Text }
      end
    end

    it 'should accept convertible values in collector using specified collector methods' do
      list = nil
      no_error {
        list = List do
          foo "Hello"
          bar "World"
        end
      }
      list.items.size.should_be 2
      list.items[0].should_be Item("Hello")
      list.items[1].should_be Text("World")
    end
  end
end
