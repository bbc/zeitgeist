require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', '#must' do
  temporary_constant :Answer do
    before :each do
    end

    it 'can be specified has params' do
      class Answer < Doodle
        has :value, :must => { "equal 42" => proc {|i| i == 42 }}
      end
      name = Answer.new(42)
      name.value.should_be 42
      expect_error(Doodle::ValidationError) { name.value = 41 }
    end

    it 'can be specified has params' do
      class Answer < Doodle
        has :value, :must => { "equal 42" => proc {|i| i == 42 }}
      end
      expect_error(Doodle::ValidationError, /equal 42/) { Answer.new(41) }
    end

    it 'can combine with #must clause defined in block' do
      class Answer < Doodle
        has :value, :must => { "be greater than 41" => proc {|i| i > 41 }} do
          must "be less than 43" do |i|
            i < 43
          end
        end
      end

      name = Answer.new(42)
      name.value.should_be 42

      expect_error(Doodle::ValidationError, /be greater than 41/) { Answer.new(41) }
      expect_error(Doodle::ValidationError, /be less than 43/) { Answer.new(43) }
    end
  end
end
