require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'instance attributes' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        has :name, :default => nil
      end
      @foo = Foo.new
    end
    after :each do
      remove_ivars :foo
    end

    it 'should create attribute' do
      @foo.name = 'Smee'
      @foo.name.should_be 'Smee'
    end

    it 'should create attribute using getter_setter' do
      @foo.name 'Smee'
      @foo.name.should_be 'Smee'
    end

    it 'should list instance attributes(false)' do
      @foo.doodle.attributes(false).keys.should_be []
    end

    it 'should list instance attributes' do
      @foo.doodle.attributes.keys.should_be [:name]
    end

    it 'should list all instance attributes(false) at class level' do
      Foo.doodle.attributes(false).keys.should_be [:name]
    end
  end
end

describe Doodle, 'class attributes(false)' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        class << self
          has :metadata
        end
      end
      @foo = Foo.new
    end
    after :each do
      remove_ivars :foo
    end

    it 'should create class attribute' do
      Foo.metadata = 'Foo metadata'
      Foo.metadata.should_be 'Foo metadata'
    end

    it 'should access @foo.class attribute via self.class' do
      @foo.class.metadata = '@foo metadata'
      @foo.class.metadata.should_be '@foo metadata'
      Foo.metadata.should_be '@foo metadata'

      Foo.metadata = 'Foo metadata'
      Foo.metadata.should_be 'Foo metadata'
      @foo.class.metadata.should_be 'Foo metadata'
    end

    it "should list all class's own attributes" do
      Foo.singleton_class.doodle.attributes(false).keys.should_be [:metadata]
    end

    it "should list all class's own attributes" do
      Foo.singleton_class.doodle.attributes.keys.should_be [:metadata]
    end
  end
end

describe Doodle, 'inherited class attributes(false)' do
  temporary_constant :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
        has :name, :default => nil
        class << self
          has :metadata
        end
      end
      class Bar < Foo
        has :location, :default => nil
        class << self
          has :notes
        end
      end
      @foo = Foo.new
      @bar = Bar.new
    end
    after :each do
      remove_ivars :foo, :bar
    end

    it 'should create inherited class attribute' do
      Foo.metadata = 'Foo metadata'
      Bar.metadata = 'Bar metadata'
      Foo.metadata.should_be 'Foo metadata'
      Bar.metadata.should_be 'Bar metadata'
      Foo.metadata.should_be 'Foo metadata'
    end

    it 'should access @foo.class attribute via self.class' do
      @foo.class.metadata = '@foo metadata'
      @foo.class.metadata.should_be '@foo metadata'
      Foo.metadata.should_be '@foo metadata'

      Foo.metadata = 'Foo metadata'
      Bar.metadata = 'Bar metadata'
      Foo.metadata.should_be 'Foo metadata'
      Bar.metadata.should_be 'Bar metadata'
      Foo.metadata.should_be 'Foo metadata'
      @foo.class.metadata.should_be 'Foo metadata'
      @bar.class.metadata.should_be 'Bar metadata'
    end

    it 'should access inherited @foo.class attribute via self.class' do
      @foo.class.metadata = '@foo metadata'
      @foo.class.metadata.should_be '@foo metadata'
      Foo.metadata.should_be '@foo metadata'
      Foo.metadata = 'Foo metadata'

      Bar.metadata = 'Bar metadata'
      Bar.metadata.should_be 'Bar metadata'
      @bar.class.metadata.should_be 'Bar metadata'

      Foo.metadata.should_be 'Foo metadata'
      @foo.class.metadata.should_be 'Foo metadata'
    end

    it "should list class's own attributes" do
      Foo.singleton_class.doodle.attributes(false).keys.should_be [:metadata]
    end

    it "should list all class's own attributes" do
      Foo.singleton_class.doodle.attributes.keys.should_be [:metadata]
    end

    it "should list class's own attributes(false)" do
      Bar.singleton_class.doodle.attributes(false).keys.should_be [:notes]
    end

    it "should list all singleton class attributes" do
      Bar.singleton_class.doodle.attributes.keys.should_be [:notes]
    end

    it "should list all inherited meta class attributes" do
      Bar.doodle.class_attributes.keys.should_be [:metadata, :notes]
    end

    it "should list all inherited class's attributes" do
      Bar.doodle.attributes.keys.should_be [:name, :location]
    end
  end
end

describe Doodle, 'singleton class attributes' do
  temporary_constant :Foo do
    before(:each) do

      class Foo
        include Doodle::Core
        has :name, :default => nil
        class << self
          has :metadata
        end
      end
      @foo = Foo.new
      class << @foo
        has :special, :default => nil
      end
    end
    after :each do
      remove_ivars :foo
    end

    it 'should allow creation of singleton class attributes' do
      @foo.special = 42
      @foo.special.should_be 42
    end

    it 'should list singleton instance attributes(false)' do
      @foo.singleton_class.doodle.attributes(false).keys.should_be [:special]
    end

    it 'should list singleton instance attributes' do
      @foo.singleton_class.doodle.attributes.keys.should_be [:special]
    end

    it 'should list instance attributes' do
      @foo.doodle.attributes.keys.should_be [:name, :special]
    end

  end
end

describe Doodle, 'inherited singleton class attributes' do
  temporary_constant :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
        has :name, :default => nil
        class << self
          has :metadata
        end
      end
      class Bar < Foo
        has :info, :default => nil
        class << self
          has :notes
        end
      end

      @foo = Foo.new
      class << @foo
        has :special, :default => nil # must give default because already initialized
      end
      @bar = Bar.new
      @bar2 = Bar.new
      class << @bar
        has :extra
      end
    end

    after :each do
      remove_ivars :foo, :bar, :bar2
    end

    it 'should allow creation of singleton class attributes' do
      @foo.special = 42
      @foo.special.should_be 42
      @bar.extra = 84
      @bar.extra.should_be 84
      proc { @foo.extra = 1 }.should raise_error(NoMethodError)
      proc { @bar2.extra = 1 }.should raise_error(NoMethodError)
      proc { @bar.special = 1 }.should raise_error(NoMethodError)
    end

    it 'should list instance attributes' do
      @foo.class.doodle.attributes(false).keys.should_be [:name]
      @bar.class.doodle.attributes(false).keys.should_be [:info]
      @bar2.class.doodle.attributes(false).keys.should_be [:info]
    end

    it 'should list instance meta attributes' do
      @foo.singleton_class.doodle.attributes(false).keys.should_be [:special]
      @bar.singleton_class.doodle.attributes(false).keys.should_be [:extra]
    end

    it 'should list singleton attributes only' do
      @foo.singleton_class.doodle.attributes.keys.should_be [:special]
      @bar.singleton_class.doodle.attributes.keys.should_be [:extra]
    end

    it 'should keep meta attributes separate' do
      @foo.special = 'foo special'
      @foo.special.should_be 'foo special'

      # CHECK

      # note: you cannot set any other values on @bar until you have set @bar.extra because it's defined as required
      @bar.extra = 'bar extra'
      @bar.extra.should_be 'bar extra'
      Foo.metadata = 'Foo meta'
      Foo.metadata.should_be 'Foo meta'
      Bar.metadata = 'Bar meta'
      Bar.metadata.should_be 'Bar meta'
      Bar.notes = 'Bar notes'
      Bar.notes.should_be 'Bar notes'

      # now make sure they haven't bumped each other off
      @foo.special.should_be 'foo special'

      @bar.extra.should_be 'bar extra'
      Foo.metadata.should_be 'Foo meta'
      Bar.metadata.should_be 'Bar meta'
      Bar.notes.should_be 'Bar notes'
    end

    it 'should inherit singleton methods from class' do
      @foo.singleton_class.respond_to?(:metadata).should_be true
      @foo.singleton_class.doodle.attributes[:metadata].should_be nil
      @foo.singleton_class.metadata = 'foo meta'
      @foo.singleton_class.instance_eval { @metadata }.should_be 'foo meta'
      @foo.singleton_class.metadata.should_be 'foo meta'
    end

    it 'should behave predictably when setting singleton attributes' do
      @bar.extra = 'bar extra'
      @bar.extra.should_be 'bar extra'
      @bar.singleton_class.metadata = 'bar meta metadata'
      @bar.singleton_class.metadata.should_be 'bar meta metadata'
      @bar.singleton_class.notes = 'bar notes'
      @bar.singleton_class.notes.should_be 'bar notes'
      proc { @foo.singleton_class.notes = 1 }.should raise_error(NoMethodError)
    end
  end
end

