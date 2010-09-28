require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'Comparable' do
  temporary_constants :Item, :List do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::List < Doodle
        has :items, :collect => Item
      end
    end

    it 'makes it possible to sort doodles' do
      list = List do
        item "B"
        item "C"
        item "A"
      end
      list.items.sort.should_be [Item("A"), Item("B"), Item("C")]
    end
  end
end
