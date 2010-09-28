require File.join(File.dirname(__FILE__), 'spec_helper')

describe Doodle, "doodle_context" do
  temporary_constants :Foo, :Bar do
    before :each do
      class ::Child < Doodle
        has :name
        has :dad do
          # there is an important difference between a block argument
          # and a Proc object (proc/lambda) argument
          # - a proc/lamba is treated as a literal argument, i.e. the
          # - value is set to a Proc
          # - a block argument, on the other hand, is instance
          #   evaluated during initialization
          # - consequences
          #   - can only be done in init block
          #   - somewhat subtle difference (from programmer's point of
          #     view) between a proc and a block
          # Also note re: Doodle.parent - its value is only valid
          # during initialization - this is a way to capture that
          # value for use later

          init { doodle.parent }
        end
      end

      class Parent < Child
        has :children, :collect => Child
      end

    end

    it 'should provide a means to find out the current parent of an item in initialization block' do
      dad = Parent 'Conn' do
        child 'Sean'
        child 'Paul'
      end

      sean = dad.children[0]
      sean.dad.name.should_be 'Conn'
      sean.doodle.parent.name.should_be 'Conn'
    end
  end
end

