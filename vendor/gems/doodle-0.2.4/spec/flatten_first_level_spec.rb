require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'flatten_first_level' do

  before :each do
    @data = [
      [1, 2, 3],
      [1, [2], 3],
      [[1, 2, 3]],
      [1, [2, 3]],
      [[1, 2], 3],
      [[1, [2], 3]],
      [1, [[2], 3]],
      [1, [[2, 3]]],
      ]
    @results = [
      [1, 2, 3],
      [1, 2, 3],
      [1, 2, 3],
      [1, 2, 3],
      [1, 2, 3],
      [1, [2], 3],
      [1, [2], 3],
      [1, [2, 3]],
      ]
  end
  after :each do
    remove_ivars :data, :results
  end

  it 'should flatten first level' do
    @data.zip(@results).each do |input, result|
      Doodle::Utils.flatten_first_level(input).should == result
    end
  end

end
