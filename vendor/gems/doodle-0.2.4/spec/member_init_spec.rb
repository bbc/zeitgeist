require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'initialization of scalar attributes from hash' do
  temporary_constant :Foo, :Bar do
    before :each do
      class Bar < Doodle
        has :name, :kind => String
        has :count, :kind => Integer
      end
      class Foo < Doodle
        has Bar
        has :v2, :kind => String, :default => "bar"
      end
    end

    it 'should initialize an attribute from a hash' do
      foo = Foo do
        bar :name => "hello", :count => 1
      end
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
    end
    it 'should fail trying to initialize with incorrect keyword values' do
      proc {
        foo = Foo do
          bar :name => 1, :count => "hello"
        end
      }.should raise_error(Doodle::ValidationError)
    end
    it 'should work with positional args' do
      foo = nil
      proc {
        foo = Foo do
          bar "hello", 1
        end
      }.should_not raise_error
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
    end
    it 'should work with block initialization' do
      foo = nil
      proc {
        foo = Foo do
          bar do
            name "hello"
            count 1
          end
        end
      }.should_not raise_error
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
    end
    it 'should work with arg and block initialization' do
      foo = nil
      proc {
        foo = Foo do
          bar "hello" do
            count 1
          end
        end
      }.should_not raise_error
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
    end
    it 'should work with keyword and block initialization' do
      foo = nil
      proc {
        foo = Foo do
          bar :name => "hello" do
            count 1
          end
        end
      }.should_not raise_error
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
    end
    it 'should raise error with invalid keyword and block initialization' do
      foo = nil
      proc {
        foo = Foo do
          bar(:name => 1) { count "hello" }
        end
      }.should raise_error(Doodle::ValidationError)
    end
    it 'should raise error with keyword and invalid block initialization' do
      foo = nil
      proc {
        foo = Foo do
          bar :name => "hello" do
            count "hello"
          end
        end
      }.should raise_error(Doodle::ValidationError)
    end
    it 'should initialize non-Doodle or Proc with simple value' do
      foo = nil
      proc {
        foo = Foo do
          bar :name => "hello", :count => 1
          v2 "Hello"
        end
      }.should_not raise_error
      foo.bar.name.should_be "hello"
      foo.bar.count.should_be 1
      foo.v2.should_be "Hello"
    end
    it 'should fail trying to initialize an inappropriate attribute (not a Doodle or Proc) from a block' do
      proc {
        foo = Foo do
          bar :name => "hello", :count => 1
          v2 { "Hello" }
        end
      }.should raise_error(ArgumentError)
    end
  end
end

