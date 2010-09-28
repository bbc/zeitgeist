require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe Doodle::Utils, 'normalize_keys' do
  sym_hash = {
    :barn => {
      :animals=>
      [
       {
         :species=>"pig"
       }
      ]
    }
  }
  string_hash = {
    "barn" => {
      "animals" =>
      [
       {
         "species"=>"pig"
       }
      ]
    }
  }

  args = [
          { :input => [string_hash], :output => {:barn=>{"animals"=>[{"species"=>"pig"}]}} },
          { :input => [sym_hash, false, :to_s], :output => {"barn"=>{:animals=>[{:species=>"pig"}]}}},
          { :input => [string_hash, true, :to_sym], :output => sym_hash },
          { :input => [sym_hash, true, :to_s], :output => string_hash },
         ]

  args.each do |arg|
    it "should produce output #{arg[:output].inspect} from args #{arg[:input].inspect})" do
      Doodle::Utils.normalize_keys(*arg[:input]).should == arg[:output]
    end
  end

end

