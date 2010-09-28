require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'to_hash' do
  temporary_constant :Foo, :Bar, :Farm, :Barn, :Animal do
    before :each do
      class ::Animal < Doodle
        has :species
      end
      class Barn < Doodle
        has :animals, :collect => Animal
      end
      class Farm < Doodle
        has Barn
      end
      class Foo < Doodle
        has :ivar1, :kind => String
      end
      class Bar < Doodle
        has :block, :kind => Proc
      end
    end

    it 'should initialize an scalar attribute from a block' do
      farm = Farm do
        barn do
          animal "pig"
        end
      end
      farm.to_hash.should_be( {:barn=>{:animals=>[{:species=>"pig"}]}} )
      farm.to_string_hash.should_be( {"barn"=>{"animals"=>[{"species"=>"pig"}]}} )
    end

    it 'should not nuke Proc-valued attributes' do
      pending "rewrite of to_hash"
      source_block = proc { puts "hello" }
      b = Bar do
        block(&source_block)
      end
      b.to_hash.should_be( { :block => source_block } )
    end

  end
end

