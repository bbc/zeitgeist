require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::DeferredBlock do
  temporary_constant :Foo do

    before :each do
      class ::Foo < Doodle
        class << self
          has :base, :init => 1
        end
        has :value do
          init { ::Foo.base + 1 }
        end
      end
    end

    it 'should dynamically assign attribute' do
      foo = ::Foo.new
      foo.value.should_be 2
      ::Foo.base = 41
      bar = ::Foo.new
      bar.value.should_be 42
      foo.value.should_be 2
    end

  end
end

