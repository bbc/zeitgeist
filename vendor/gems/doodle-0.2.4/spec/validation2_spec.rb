# this file is frankly a bit of a mess - trying to do too many things
# at once

require File.dirname(__FILE__) + '/spec_helper.rb'

shared_code = proc do
  class ::DateRange < Doodle
    has :start_date, :kind => Date do
      from String do |s|
        Date.parse(s)
      end
      from Array do |y,m,d|
        #p [:from, Array, y, m, d]
        Date.new(y, m, d)
      end
      from Integer do |jd|
        #Doodle::Debug.d { [:converting_from, Integer, jd] }
        Date.new(*Date.send(:jd_to_civil, jd))
      end
      #Doodle::Debug.d { [:start_date, self, self.class] }
      default { Date.today }
    end
    has :end_date, :kind => Date do
      from String do |s|
        Date.parse(s)
      end
      from Array do |y,m,d|
        #p [:from, Array, y, m, d]
        Date.new(y, m, d)
      end
      from Integer do |jd|
        #Doodle::Debug.d { [:converting_from, Integer, jd] }
        Date.new(*Date.send(:jd_to_civil, jd))
      end
      default { start_date }
    end
    must "have end_date >= start_date" do
      end_date >= start_date
    end
  end
end

describe :DateRange, ' validation' do
  temporary_constants :DateRange do

    before :each, &shared_code
    
    it 'should not raise an exception if end_date >= start_date' do
      proc { DateRange.new('2007-01-01', '2007-01-02') }.should_not raise_error
    end

    it 'should raise an exception if end_date < start_date' do
      proc { DateRange.new('2007-11-01', '2007-01-02') }.should raise_error
    end
  end
end

[:DateRange, :DerivedDateRange, :SecondLevelDerivedDateRange].each do |klass|

  describe klass, ' validation' do
    temporary_constants :DateRange, :DerivedDateRange, :SecondLevelDerivedDateRange do

      before :each, &shared_code
      before :each do

        class ::DerivedDateRange < DateRange
        end

        class ::SecondLevelDerivedDateRange < DateRange
        end

        @klass = Object.const_get(klass)
        @meth = @klass.method(:new)

      end

      it 'should not raise an exception if end_date > start_date' do
        proc { @meth.call('2007-01-01', '2007-01-02') }.should_not raise_error
      end

      it 'should not raise an exception if end_date == start_date' do
        proc { @klass.new('2007-01-02', '2007-01-02') }.should_not raise_error
      end

      it 'should raise an exception if end_date is < start_date' do
        proc { @klass.new('2007-01-03', '2007-01-02') }.should raise_error(Doodle::ValidationError)
      end

      # distinguish between objects which have invalid classes and objects which have classes
      # which can be converted (i.e. in from clause) but which have unconvertible values

      invalid_dates = [Object.new, Object, Hash.new, { :key => 42 }, 1.2, :today]
      keys = [:start_date, :end_date]
  
      keys.each do |key|
        invalid_dates.each do |o|
          it "should not validate #{o.inspect} for #{key}" do
            proc { @klass.new(key => o) }.should raise_error(Doodle::ValidationError)
          end
        end
      end

      unconvertible_dates = [
        'Hello', 
        [], 
        'tomorrow', 
        'today', 
        'yesterday',
        "-9999999999999991-12-31",
        "9999999999999990-12-31", 
        9999999999999999999, 
        -9999999999999999999,
        ]
      keys = [:start_date, :end_date]

      keys.each do |key|
        unconvertible_dates.each do |o|
          it "should not convert #{o.inspect} to #{key}" do
            proc { @klass.new(key => o) }.should raise_error(Doodle::ConversionError)
          end
        end
      end

      # could do with more bad_dates...
      # note, these are splatted so need [] around args
      bad_date_pairs = [
                        [[2007,1,2],[2007,1,1]],
                        [{ :end_date => '2007-01-01' }],
                        [{ :start_date => '2007-01-01', :end_date => '2006-01-01' }]
                       ]
  
      bad_date_pairs.each do |o|
        it "should not allow #{o.inspect[1..-2]}" do
          proc { @klass.new(*o) }.should raise_error(Doodle::ValidationError)
        end
      end
  
      # note, these are splatted so need [] around args
      good_dates = [
                    [[2007,1,1],[2007,1,2]],
                    [{ :start_date => '2007-01-01' }],
                    [{ :start_date => '2007-01-01', :end_date => '2007-01-01' }],
                    [{ :start_date => -1, :end_date => 0 }]
                   ]
  
      good_dates.each do |o|
        it "should allow #{o.inspect[1..-2]}" do
          proc { @klass.new(*o) }.should_not raise_error
        end
      end
    end
  end

  describe klass, ' defaults' do
    temporary_constants :AttributeDate, :Base, :DateRange, :DerivedDateRange, :SecondLevelDerivedDateRange do
      before :each, &shared_code
      before :each do
        class ::DerivedDateRange < DateRange
        end

        class ::SecondLevelDerivedDateRange < DateRange
        end

        @klass = Object.const_get(klass)
        @dr = @klass.new
      end
  
      it 'should have default start_date == Date.today' do
        @dr.start_date == Date.today
      end

      it 'should have default end_date == start_date' do
        @dr.end_date.should == @dr.start_date
      end
    end
  end

  describe klass, ' setting attributes after initialization' do
    temporary_constants :AttributeDate, :Base, :DateRange, :DerivedDateRange, :SecondLevelDerivedDateRange do
      before :each, &shared_code
      before :each do
        class ::DerivedDateRange < DateRange
        end

        class ::SecondLevelDerivedDateRange < DateRange
        end

        @klass = Object.const_get(klass)
        @dr = @klass.new
      end

      it "should not allow end_date < start_date" do
        proc { @dr.end_date = @dr.start_date - 1 }.should raise_error(Doodle::ValidationError)
      end

      it "should allow end_date >= start_date" do
        proc { @dr.end_date = @dr.start_date + 1 }.should_not raise_error
      end

      it "should allow changing start_date (and have dependent end_date follow)" do
        proc { @dr.start_date = @dr.start_date + 1 }.should_not raise_error
        @dr.end_date.should == @dr.start_date
      end

      it "should not raise an error when changing start_date and changing end_date using doodle.defer_validation" do
        proc {
          @dr.doodle.defer_validation do
            self.start_date = self.start_date + 1
            self.end_date = self.start_date
          end
        }.should_not raise_error
      end

      it "should allow changing start_date and changing end_date using doodle.defer_validation" do
        @dr.doodle.defer_validation do
          start_date start_date + 1
          end_date start_date
        end
        @dr.start_date.should >= @dr.end_date
      end
  
      it "should not allow changing start_date to be > end_date" do
        proc {
          @dr.end_date = @dr.start_date
          @dr.start_date = @dr.start_date + 1
        }.should raise_error(Doodle::ValidationError)
      end

      it "should not allow changing start_date to be > end_date" do
        proc {
          @dr.instance_eval {
            end_date  start_date
            start_date start_date + 1
          }
        }.should raise_error(Doodle::ValidationError)
      end
  
      it "should not allow changing end_date to be < start_date" do
        proc {
          @dr.instance_eval {
            end_date  start_date - 1
          }
        }.should raise_error(Doodle::ValidationError)
      end
  
    end
  end
end
