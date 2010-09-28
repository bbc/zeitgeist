require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'assigned? with default' do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :name, :default => "XXX"
      end
    end

    it 'should return false if attribute not assigned' do
      foo = Foo.new
      foo.name.should_be "XXX"
      foo.assigned?(:name).should_be false
      foo.clear!(:name)
      foo.name.should_be "XXX"
    end

    it 'should return true if attribute assigned' do
      foo = Foo.new('foo')
      foo.name.should_be "foo"
      foo.assigned?(:name).should_be true
      foo.clear!(:name)
      foo.name.should_be "XXX"
    end

  end
end

describe Doodle, 'assigned? with init' do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :name, :init => "XXX"
      end
    end

    it 'should return true if attribute has init even when not specifically assigned' do
      foo = Foo.new
      foo.name.should_be "XXX"
      foo.assigned?(:name).should_be true
      foo.clear!(:name)
      foo.name.should_be "XXX"
    end

    it 'should return true if attribute has init and has been assigned' do
      foo = Foo.new('foo')
      foo.name.should_be "foo"
      foo.assigned?(:name).should_be true
      foo.clear!(:name)
      foo.name.should_be "XXX"
    end

  end
end
