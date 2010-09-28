require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'attributes with defaults' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        has :name, :default => 'D1'
        class << self
          has :metadata, :default => 'D2'
        end
      end
      @foo = Foo.new
      class << @foo
        has :special, :default => 'D3'
      end
    end
  
    it 'should have instance attribute default via class' do
      Foo.doodle.attributes[:name].default.should_be 'D1'
    end
    it 'should have instance attribute default via instance' do
      @foo.doodle.attributes[:name].default.should_be 'D1'
    end
    it 'should have class attribute default via class.meta' do
      Foo.singleton_class.doodle.attributes(false)[:metadata].default.should_be 'D2'
    end
    it 'should have class attribute default via class.meta' do
      Foo.singleton_class.doodle.attributes[:metadata].default.should_be 'D2'
    end
    it 'should have singleton attribute default via instance.singleton_class.doodle.attributes(false)' do
      @foo.singleton_class.doodle.attributes(false)[:special].default.should_be 'D3'
    end
    it 'should have singleton attribute default via instance.singleton_class.doodle.attributes' do
      @foo.singleton_class.doodle.attributes[:special].default.should_be 'D3'
    end
    it 'should have singleton attribute name by default' do
      @foo.name.should_be 'D1'
    end
    it 'should have singleton attribute name by default' do
      Foo.metadata.should_be 'D2'
    end
    it 'should have singleton attribute special by default' do
      @foo.special.should_be 'D3'
    end

    it 'should not have a @name instance variable' do
      @foo.instance_variables.include?("@name").should_be false
      @foo.instance_variables.sort.should_be []
    end
    it 'should not have a @metadata class instance variable' do
      Foo.instance_variables.include?("@metadata").should_be false
      Foo.instance_variables.sort.should_be []
    end
    it 'should not have @special singleton instance variable' do
      @foo.singleton_class.instance_variables.include?("@special").should_be false
      @foo.singleton_class.instance_variables.sort.should_be []
    end
  end
end

describe Doodle, 'defaults which have not been set' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :baz
      end
    end

    it 'should raise Doodle::ValidationError if required attributes not passed to new' do
      proc { foo = Foo.new }.should raise_error(Doodle::ValidationError)
    end

    it 'should not raise error if required attributes passed to new' do
      proc { foo = Foo.new(:baz => 'Hi' ) }.should_not raise_error
    end
  end
end

describe Doodle, 'defaults which have been set' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :baz, :default => 'Hi!'
        has :start do
          default { Date.today }
        end
      end
      @foo = Foo.new
    end

    it 'should have default value set from hash arg' do
      @foo.baz.should_be 'Hi!'
    end

    it 'should have default value set from block' do
      @foo.start.should_be Date.today
    end

    it 'should denote that default value is a default' do
      @foo.default?(:start).should_be true
      @foo.default?(:baz).should_be true
    end

    it 'should denote that default value is not a default if it has been assigned' do
      @foo.baz = "Hi"
      @foo.default?(:baz).should_not_be true
      @foo.start = Date.today
      @foo.default?(:start).should_not_be true
    end

  end
end

describe Doodle, "overriding inherited defaults" do
  temporary_constant :Text, :Text2, :KeyValue do
    before :each do
      class KeyValue < Doodle
        has :name
        has :value
      end
      class Text < KeyValue
        has :name, :default => "text"
      end
      class Text2 < Text
        has :value, :default => "any2"
      end
    end
  
    it 'should not raise error if initialized with required values' do
      proc { Text.new(:value => 'any') }.should_not raise_error
    end
  
    it 'should allow initialization using defaults' do
      text = Text.new(:value => 'any')
      text.name.should_be 'text'
      text.value.should_be 'any'
    end
  
    it 'should raise Doodle::ValidationError if initialized without all required values' do
      proc { KeyValue.new(:value => 'Enter name:') }.should raise_error(Doodle::ValidationError)
    end
  
    it 'should allow initialization using inherited defaults' do
      text = Text2.new
      text.name.should_be 'text'
      text.value.should_be 'any2'
    end
  end
end
