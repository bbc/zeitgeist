$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'
require 'yaml'

class Child < Doodle
  has :name
  has :dad do
    # I'm treating block arguments and Proc object (proc/lambda) arguments
    # to :init differently:
    # - a proc/lamba is treated as a literal argument, i.e. the
    # - value is set to a Proc
    # - a block argument, on the other hand, is instance
    # - evaluated during initialization
    # - consequences
    #   - can only be done in init block
    #   - somewhat subtle difference (from programmer's point of
    #   - view) between a proc and a block
    init do
      doodle.parent
    end
  end
end

class Parent < Child
  has :children, :collect => Child
end

parent = Parent 'Conn' do
  child 'Sean'
end

puts parent.to_yaml



