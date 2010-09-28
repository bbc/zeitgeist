require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::DoodleAttribute, 'basics' do
  temporary_constants :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
        has :ivar1, :default => 'Hello'
        class << self
          has :cvar1
        end
      end
      class Bar < Foo
        has :ivar2
        class << self
          has :cvar2
        end
      end

      @foo = Foo.new
      class << @foo
        has :svar1
      end
      @bar = Bar.new :ivar2 => 'Hi'
      class << @bar
        has :svar2
      end
    end

    after :each do
      @bar = nil
      @foo = nil
    end

    it 'should have attribute :ivar1 with default defined' do
      @foo.doodle.attributes[:ivar1].default.should == 'Hello'
    end

    it 'should have default name' do
      @foo.ivar1.should == 'Hello'
    end

    it 'should not have an instance variable for a default' do
      @foo.instance_variables.include?('@name').should == false
    end

    it 'should have name required == false (because has default)' do
      @foo.doodle.attributes[:ivar1].required?.should == false
    end

    it 'should have ivar2 required == true' do
      @bar.doodle.attributes[:ivar2].required?.should == true
    end

    it 'should have name.optional? == true (because has default)' do
      @foo.doodle.attributes[:ivar1].optional?.should == true
    end

    it 'should inherit attribute from parent' do
      @bar.doodle.attributes[:ivar1].should == @foo.doodle.attributes[:ivar1]
    end

    it 'should have ivar2.optional? == false' do
      @bar.doodle.attributes[:ivar2].optional?.should == false
    end

#     it "should have doodle.parents in correct order" do
#       expected_doodle.parents = RUBY_VERSION <= "1.8.6" ? [Foo, Object] : [Foo, Object, BasicObject]
#       Bar.doodle.parents.should == expected_doodle.parents
#     end

    it "should have Bar's singleton doodle.parents in reverse order of definition" do
      @bar.singleton_class.doodle.parents.should == []
    end

    it 'should have singleton_class attributes in order of definition' do
      Bar.singleton_class.doodle.attributes.keys.should == [:cvar2]
    end

    it 'should have inherited class_attributes in order of definition' do
      Bar.doodle.class_attributes.keys.should == [:cvar1, :cvar2]
    end

    it 'should have inherited class_attributes in order of definition' do
      @bar.doodle.class_attributes.keys.should == [:cvar1, :cvar2]
    end

    it 'should have local class attributes in order of definition' do
      Bar.singleton_class.doodle.attributes(false).keys.should == [:cvar2]
    end

    # bit iffy this test - testing implementation, not interface
    it 'should not inherit singleton doodle.local_attributes' do
      @bar.singleton_class.class_eval { doodle.send(:collect_inherited, :local_attributes).map { |x| x[0]} }.should == []
    end

    it 'should not inherit singleton attributes#1' do
      @bar.singleton_class.doodle.attributes.map { |x| x[0]} .should == [:svar2]
    end

    it 'should not inherit singleton attributes#2' do
      @bar.singleton_class.doodle.attributes.keys.should == [:svar2]
    end

    it 'should not inherit singleton attributes#3' do
      @bar.singleton_class.doodle.attributes(false).keys.should == [:svar2]
    end

    it 'should show singleton attributes in attributes' do
      @bar.doodle.attributes.keys.should == [:ivar1, :ivar2, :svar2]
    end

  end
end

describe Doodle::DoodleAttribute, 'attribute order' do
  temporary_constants :A, :B, :C do
    before :each do
      class A < Doodle
        has :a
      end

      class B < A
        has :b
      end

      class C < B
        has :c
      end
    end

#     it 'should keep order of inherited attributes' do
#       expected_doodle.parents = RUBY_VERSION <= "1.8.6" ? [B, A, Doodle, Object] : [B, A, Doodle, Object, BasicObject]
#       C.doodle.parents.should == expected_doodle.parents
#     end

    it 'should keep order of inherited attributes' do
      C.doodle.attributes.keys.should == [:a, :b, :c]
    end
  end
end

describe Doodle::DoodleAttribute, 'attribute order' do
  it 'should reject attributes without names' do
    proc { Doodle::DoodleAttribute.params_from_args(:kind => String) }.should raise_error(ArgumentError)
  end

  it 'should not allow changing name' do
    proc { Doodle::DoodleAttribute.new(:name => "foo")}.should_not raise_error(ArgumentError)
    d = Doodle::DoodleAttribute.new(:name => "foo")
    d.name.should_be :foo
    proc { d.name = :bar }.should raise_error(Doodle::ReadOnlyError)
  end

  it 'should ensure that attribute name is readonly' do
    d = Doodle::DoodleAttribute.new(:name => "foo", :readonly => true)
    d.name.should_be :foo
    proc { d.name = "foo" }.should raise_error(Doodle::ReadOnlyError)
  end
end

