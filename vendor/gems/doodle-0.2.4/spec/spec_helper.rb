require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'doodle'
require 'date'

class Object
  # get rid of those annoying warnings about useless ==
  def should_be(other)
    should == other
  end
  def should_not_be(other)
    should_not == other
  end
end

# functions to help clean up namespace after defining classes
def undefine_const(*consts)
  consts.each do |const|
    if Object.const_defined?(const)
      Object.send(:remove_const, const)
    end
  end
end

def raise_if_defined(*args)
  where = args.shift
  defined = args.select{ |x| Object.const_defined?(x)}
  raise "Namespace pollution #{where}: #{defined.join(', ')}" if defined.size > 0
end

def temporary_constants(*args, &block)
  constants = Object.constants.dup
  before :each do
    raise_if_defined(:before, *args)
  end
  after :each do
    undefine_const(*args)
  end
  crud = Object.constants - constants
  if crud.size > 0
    raise Exception, "Namespace crud: #{crud.map{ |x| x.to_s}.join(', ')}"
  end
  raise_if_defined(:begin, *args)
  yield
  raise_if_defined(:end, *args)
end
alias :temporary_constant :temporary_constants

def remove_ivars(*args)
  args.each do |ivar|
    remove_instance_variable "@#{ivar}"
  end
end

def expect_ok(&block)
  proc(&block).should_not raise_error
end
alias :no_error :expect_ok

def expect_error(*args, &block)
  proc(&block).should raise_error(*args)
end

def expect(&block)
  block.call.should_be true
end

def expect_not(&block)
  block.call.should_be false
end
