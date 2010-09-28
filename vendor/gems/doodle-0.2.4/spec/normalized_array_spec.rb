require File.dirname(__FILE__) + '/spec_helper.rb'

class StringArray < NormalizedArray
  def normalize_value(v)
    #p [self.class, :normalize_value, v]
    v.to_s
  end
end

describe NormalizedArray do
  before :each do
    @sa = StringArray.new(3) { |i|
      42
    }
  end
  it 'should convert values to strings' do
    expect { @sa[1] == "42" }
    expect { @sa[1] != 42 }
    expect_error { @sa.values == ["42"] * 3 }
    expect_error { @sa.values == [42] }
  end
end

describe NormalizedArray do
  before :each do
    @sa = StringArray.new([1,2,3])
  end

  it 'integrates with Arrays' do
    expect_ok {  sa = StringArray.new([1,2,3]) }
    expect { @sa == ["1", "2", "3"] }
    expect { (@sa | ["4", "5", "6"]) == ["1", "2", "3", "4", "5", "6"] }
    expect { (@sa | [4, 5, 6]) == ["1", "2", "3", 4, 5, 6] }
    expect { (@sa | [4, 5, 6]).class == Array }

    # equality
    expect { @sa == ["1", "2", "3"] }
    expect { ["1", "2", "3"] == @sa }

    expect_error { sa.eql?( [1, 2, 3] )}
    expect_error { sa == [1, 2, 3] }
    expect_error { [1, 2, 3] == sa }
  end
end

describe NormalizedArray do
  temporary_constant :BoundedArray4, :TypedStringArray do
    before :each do
      TypedStringArray = NormalizedArray::TypedArray(String)
      BoundedArray4 = NormalizedArray::BoundedArray(4)
      @ca = BoundedArray4.new([1,2,3])
    end

    it 'C' do
      expect { @ca == [1, 2, 3] }
      expect_ok { @ca[4] = 42 }
      expect_error(IndexError) { @ca[5] = 42 }
      #expect_ok(/out of range/) { @ca[5] = 42 }
      expect_error(IndexError) { @ca[5] = 42 }

      expect_ok { ca = BoundedArray4.new([1,2,3,4,5]) }
      expect_error { ca = BoundedArray4.new([1,2,3,4,5,6]) }

      expect_error { sa = TypedStringArray.new([1,2,3]) }
      expect_ok { sa = TypedStringArray.new(["1","2","3"]) }
      expect_error(/Fixnum\(1\) is not a kind of String/) { TypedStringArray[1,2,3] }
      expect_error(TypeError) { TypedStringArray[1,2,3] }
    end
  end
end

describe NormalizedArray do
  temporary_constants :TypedIntegerArray, :StringOrIntegerArray do
    before :each do
      TypedIntegerArray = NormalizedArray::TypedArray(Integer)
      StringOrIntegerArray = NormalizedArray::TypedArray(Integer, String)

      @ia = TypedIntegerArray.new([1,2,3])
      @ma = StringOrIntegerArray.new([1,"2",3])
    end

    it 'can constrain elements to multiple types' do
      expect_error { @ia[1] = "hello" }
      expect_ok { ma = StringOrIntegerArray.new([1,"2",3]) }
      expect_ok { @ma[0] = "hello" }
      expect_error { @ma[1] = Date.new }
    end
  end
end

describe ArraySentence do
  it 'provides a way to join array elements in a natural sentence' do
    expect {
      ma = [].extend(ArraySentence)
      ma.join_with(', ', ' and ') == ""
    }

    expect {
      ma = [nil].extend(ArraySentence)
      ma.join_with(', ', ' and ') == ""
    }

    expect {
      ma = [nil, nil].extend(ArraySentence)
      ma.join_with(', ', ' and ') == " and "
    }

    expect {
      ma = [nil, nil, nil].extend(ArraySentence)
      ma.join_with(', ', ' and ') == ",  and "
    }

    expect {
      ma = [1].extend(ArraySentence)
      ma.join_with(', ', ' and ') == "1"
    }

    expect {
      ma = [1, 2].extend(ArraySentence)
      ma.join_with(', ', ' and ') == "1 and 2"
    }

    expect {
      ma = [1, 2, 3].extend(ArraySentence)
      ma.join_with(', ', ' or ') == "1, 2 or 3"
    }

    expect {
      ma = [1, 2, 3].extend(ArraySentence)
      ma.join_with(', ', ' and ') == "1, 2 and 3"
    }

  end
end
