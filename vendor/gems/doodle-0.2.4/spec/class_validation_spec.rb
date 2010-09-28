require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'class validations' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle
        class << self
          has :meta, { :default => "data", :kind => String } do
            must "be >= 3 chars long" do |s|
              s.size >= 3
            end
          end
        end
      end
      class Bar < Foo
      end
    end

    it 'should validate singleton class attributes' do
      proc { Foo.meta = 1 }.should raise_error(Doodle::ValidationError) 
    end

    it 'should reject invalid singleton class attributes specified with must clause' do
      proc { Foo.meta = "a" }.should raise_error(Doodle::ValidationError) 
    end
    
    it 'should accept valid singleton class attributes specified with must clause' do
      proc { Foo.meta = "abc" }.should_not raise_error
    end

    it 'should validate inherited singleton class attributes' do
      proc { Bar.meta = 1 }.should raise_error(Doodle::ValidationError) 
    end

    it 'should reject invalid inherited singleton class attributes specified with must clause' do
      proc { Bar.meta = "a" }.should raise_error(Doodle::ValidationError) 
    end
    
    it 'should accept valid inherited singleton class attributes specified with must clause' do
      proc { Bar.meta = "abc" }.should_not raise_error
    end

  end
end


