require File.dirname(__FILE__) + '/spec_helper.rb'

describe NormalizedHash do

  before :each do
    @sh = StringKeyHash.new { |h,k| h[k] = 42 }
  end
  it 'should normalize keys' do
    expect { @sh[:a] == 42 }
    expect { @sh["a"] == 42 }
    expect { @sh.keys == ["a"] }
    sh = StringKeyHash.new( { :a => 2 } )
    expect { sh.keys == ["a"] }
    bh = StringKeyHash.new( { :a => 2 } ) { |h,k| h[k] = 42}
    expect { bh[:b] == 42 }
    expect { bh.keys.sort == ["a", "b"] }
  end
end

describe NormalizedHash do

  it 'should normalize keys' do
    yh = SymbolKeyHash.new { |h,k| h[k] = 42 }
    expect { yh[:a] == 42 }
    expect { yh["a"] == 42 }
    expect { yh.keys == [:a] }
  end

  it 'should normalize keys passed in initializing hash' do
    yh = SymbolKeyHash.new( { :a => 2 } )
    expect { yh.keys == [:a] }
  end

end

describe NormalizedHash do

  before :each do
    @sh = StringHash.new( { :a => 2 } ) { |h,k| h[k] = 42}
  end

  it 'should normalize values' do
    expect { @sh[:b] == "42" }
    expect { @sh.keys.sort == ["a", "b"] }
    expect { @sh.values.sort == ["2", "42"] }
  end

  it 'should normalize values' do
    skh = SymbolKeyHash.new( { :a => 2 } ) { |h,k| h[k] = 42}
    expect { skh.values == [2] }
    skh['b'] = 42
    expect { skh.key?(:a) && skh.key?(:b) }
    expect { skh.invert.keys == [2, 42] }
    nskh = StringKeyHash.new(skh.invert)
    expect { nskh.keys.sort == ["2", "42"] }
    nsh = StringHash.new(skh.invert)
    expect { nsh.keys.sort == ["2", "42"] }
    expect { nsh.values.sort == ["a", "b"] }
  end
end

describe NormalizedHash do
  temporary_constant :StringIntegerHash do
    before :each do
      StringIntegerHash = NormalizedHash::TypedHash(String, Integer)
    end

    it 'should constrain to multiple types' do
      expect_ok { sih = StringIntegerHash[:a => 1, :b => "Hello"] }
      expect_error(TypeError) { sih = StringIntegerHash[:a => 1, :b => Date.new] }
      expect_ok {
        sih = StringIntegerHash.new
        sih[:a] = 1
        sih[:b] = "hello"
      }

      expect_error(TypeError) {
        sih = StringIntegerHash.new
        sih[:c] = Date.new
      }
    end
  end
end

describe NormalizedHash do
  temporary_constant :ReverseStringHash do
    before :each do
      ReverseStringHash = NormalizedHash::TypedHash() do |v|
        if v.kind_of?(String)
          v.reverse
        else
          v
        end
      end
    end
  end

  it 'should enable defining normalization using a block' do
    expect {
      sih = ReverseStringHash[:a => 123, :b => "Hello"]
      sih[:a] == 123 && sih[:b] == "Hello".reverse
    }

    expect {
      sih = ReverseStringHash.new
      sih[:a] = 123
      sih[:b] = "Hello"
      sih[:a] == 123 && sih[:b] == "Hello".reverse
    }
  end

end
