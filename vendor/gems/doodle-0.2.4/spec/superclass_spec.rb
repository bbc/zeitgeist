require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'doodle.parents' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
      end
      @foo = Foo.new
      @sc = class << @foo; self; end
      @scc = class << @sc; self; end
      @sclass_doodle_root = class << Doodle; self; end
      @sclass_foo = class << @foo; class << self; self; end; end
    end
  
    it 'should have no singleton doodle.parents ' do
      @sc.doodle.parents.should == []
    end

#     it "should have singleton class's singleton class doodle.parents == []" do
#       expected_doodle.parents = RUBY_VERSION <= "1.8.6" ? [] : [Module, Object, BasicObject]
#       @scc.doodle.parents.should == expected_doodle.parents
#     end
  end
end

