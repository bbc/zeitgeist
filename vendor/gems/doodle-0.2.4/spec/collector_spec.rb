require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, "Default collector" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :list, :collect => :item
      end
      @foo = Foo do
        item "Hello"
        item "World"
      end
    end
    after :each do
      remove_ivars :foo
    end

    it "should define a collector method :item" do
      @foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
    end

    it "should collect items into attribute :list" do
      @foo.list.should_be ["Hello", "World"]
    end

  end
end

describe Doodle, "Simple collector" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :list, :init => [], :collect => :item
      end
      @foo = Foo do
        item "Hello"
        item "World"
      end
    end
    after :each do
      remove_ivars :foo
    end

    it "should define a collector method :item" do
      @foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
    end

    it "should collect items into attribute :list" do
      @foo.list.should_be ["Hello", "World"]
    end

  end
end

describe Doodle, "Typed collector with default collector name" do
  temporary_constant :Event, :Location do
    before :each do
      class ::Location < Doodle
        has :name, :kind => String
      end
      class ::Event < Doodle
        has :locations, :init => [], :collect => ::Location
      end
      @event = Event do
        location "Stage 1"
        # todo: move this into spec
        # should handle collected arguments with block only
        location do
          name "Stage 2"
        end
      end
    end
    after :each do
      remove_ivars :event
    end

    it "should define a collector method :location" do
      @event.methods.map{ |x| x.to_sym }.include?(:location).should_be true
    end

    it "should collect items into attribute :list" do
      @event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
    end

  end
end

describe Doodle, "Typed collector with specified collector name" do
  temporary_constant :Location, :Event do
    before :each do
      class ::Location < Doodle
        has :name, :kind => String
      end
      class ::Event < Doodle
        has :locations, :init => [], :collect => { :place => :Location }
      end
    end
    it "should define a collector method :place" do
      Event.instance_methods.map{ |x| x.to_sym}.include?(:place).should_be true
    end
  end
end

describe Doodle, "typed collector with specified collector name" do
  temporary_constant :Location, :Event do
    before :each do
      class ::Location < Doodle
        has :name, :kind => String
      end
      class Event < Doodle
        has :locations, :init => [], :collect => { :place => ::Location }
      end
    end
    it "should collect items into attribute :list" do
      event = nil
      expect_ok {
        event = Event do
          place "Stage 1"
          place "Stage 2"
        end
      }
      event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
      event.locations.map{|loc| loc.class}.should_be [::Location, ::Location]
    end
  end
end

describe Doodle, "typed collector with specified collector name initialized from hash (with default :init param)" do
  # note: this spec also checks for resolving collector class
  temporary_constant :Location, :Event do
    before :each do
      class ::Location < Doodle
        has :name, :kind => String
        has :events, :collect => :Event
      end
      class ::Event < Doodle
        has :name, :kind => String
        has :locations, :collect => :Location
      end
    end
    it "should collect items from hash" do
      event = nil
      data = {
        :name => 'RAR',
        :locations =>
        [
         { :name => "Stage 1", :events =>
           [
            { :name => 'Foobars',
              :locations =>
              [ { :name => 'Backstage' } ] } ] }, { :name => "Stage 2" } ] }
      # note: wierd formatting above simply to pass coverage
      expect_ok {
        event = Event(data)
      }
      event.locations.map{|loc| loc.name}.should_be ["Stage 1", "Stage 2"]
      event.locations.map{|loc| loc.class}.should_be [::Location, ::Location]
      event.locations[0].events[0].kind_of?(Event).should_be true
    end
  end
end

describe Doodle, "Simple keyed collector" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :list, :collect => :item, :key => :size
      end
      @foo = Foo do
        item "Hello"
        item "World"
      end
    end
    after :each do
      remove_ivars :foo
    end

    it "should define a collector method :item" do
      @foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
    end

    it "should collect items into attribute :list" do
      # @foo.list.should_be( Doodle::OrderedHash[5, "World"] )
      @foo.list.to_a.flatten.should_be( [5, "World"] )
    end

  end
end

describe Doodle, "Simple keyed collector #2" do
  temporary_constant :Foo, :Item do
    before :each do
      class ::Item < Doodle
        has :name
      end
      class ::Foo < Doodle
        has :list, :collect => Item, :key => :name
      end
    end

    it "should define a collector method :item" do
      foo = Foo.new
      foo.methods.map{ |x| x.to_sym }.include?(:item).should_be true
      foo.respond_to?(:item).should_be true
    end

    it "should collect items into attribute :list #1" do
      foo = Foo do
        item "Hello"
        item "World"
      end
      foo.list.to_a.sort.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end

    it "should collect keyword argument enumerable into attribute :list" do
      foo = Foo(:list =>
                [
                 { :name => "Hello" },
                 { :name => "World" }
                ]
                )
      foo.list.to_a.sort.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end

    it "should collect positional argument enumerable into attribute :list" do
      foo = Foo([
                { :name => "Hello" },
                { :name => "World" }
                ]
                )
      foo.list.to_a.sort.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end

    it "should collect named argument hash into attribute :list" do
      foo = Foo(:list => {
                  "Hello" => { :name => "Hello" },
                  "World" => { :name => "World" }
                }
                )
      foo.list.to_a.sort.map{ |k, v| [k, v.class, v.name] }.should_be( [["Hello", Item, "Hello"], ["World", Item, "World"]] )
    end

  end
end

describe Doodle, 'using String as collector' do
  temporary_constant :Text do
    before :each do
      #: definition
      class Text < Doodle
        has :body, :init => "", :collect => :line
        def to_s
          body
        end
      end
    end

    it 'should not raise an exception' do
      expect_ok {
        text = Text do
          line "line 1"
          line "line 2"
        end
      }
    end

    it 'should concatenate strings' do
      text = Text do
        line "line 1"
        line "line 2"
      end
      text.to_s.should_be "line 1line 2"
    end
  end
end

describe Doodle, 'collecting text values into non-String collector' do
  # this is a regression test - when collecting String values into a
  # non-String accumulator should instantiate from
  # collector_class.new(value)
  temporary_constants :Name, :TextValue, :Signature do
    before :each do
      class ::Name < Doodle
        has :value
      end
      class ::Signature < Doodle
        has Name
      end
      class ::SignedBy  < Doodle
        has :signatures, :collect => Signature
      end
    end

    it 'should not raise an exception' do
      expect_ok {
        signed_by = SignedBy do
          signature "Sean"
        end
      }
    end

    it 'should convert String values to instances of collector class' do
      signed_by = SignedBy do
        signature "Sean"
      end
      signed_by.signatures.first.class.should_be Signature
      signed_by.signatures.first.name.class.should_be Name
      signed_by.signatures.first.name.value.should_be "Sean"
    end
  end
end

describe Doodle, ':collect' do
  temporary_constants :ItemList, :Item do

    before :each do
      class ::Item < Doodle
        has :title, :kind => String
      end
      class ItemList < Doodle
        has :items, :collect => Item
        # TODO: add warning/exception if collection name same as item name
      end
    end

    it 'should allow adding items of specified type' do
      expect_ok {
        list = ItemList do
          item Item("one")
          item Item("two")
        end
      }
    end

    it 'should allow adding items of specified type via implicit type constructor' do
      expect_ok {
        list = ItemList do
          item "one"
          item "two"
        end
      }
    end

    it 'should restrict collected items to specified type' do
      expect_error(Doodle::ValidationError) {
        list = ItemList do
          item Date.new
        end
      }
    end

  end
end

describe Doodle, ':collect' do
  temporary_constants :Canvas, :Shape, :Circle, :Square do
    before :each do
      class ::Shape < Doodle
        has :x
        has :y
      end
      class ::Circle < Shape
        has :radius
      end
      class ::Square < Shape
        has :size
      end
    end

    it 'should accept an array of types' do
      class ::Canvas < Doodle
        has :shapes, :collect => [Circle, Square]
      end
      canvas = Canvas do
        circle 10,10,5
        square 20,30,40
      end
      canvas.shapes.size.should_be 2
      canvas.shapes[0].kind_of?(Circle).should_be true
      canvas.shapes[1].should_be Square(20, 30, 40)
    end

    it 'should accept a hash of types' do
      class ::Canvas < Doodle
        has :shapes, :collect => { :circle => Circle, :square => Square }
      end
      canvas = Canvas do
        circle 10,10,5
        square 20,30,40
      end
      canvas.shapes.size.should_be 2
      canvas.shapes[0].kind_of?(Circle).should_be true
      canvas.shapes[1].kind_of?(Square).should_be true
    end
  end
end

