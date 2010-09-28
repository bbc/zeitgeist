require File.dirname(__FILE__) + '/spec_helper.rb'

describe :DateRange, 'validation & conversions' do
  temporary_constants :DateRange do
    
    before :each do

      class ::DateRange < Doodle
        has :start_date, :kind => Date do
          Doodle::Debug.d { [:start_date, self, self.class] }
          from String do |s|
            Date.parse(s)
          end
          from Array do |y,m,d|
            #p [:from, Array, y, m, d]
            Date.new(y, m, d)
          end
          from Integer do |jd|
            Doodle::Debug.d { [:converting_from, Integer, jd] }
            Date.new(*Date.send(:jd_to_civil, jd))
          end
          default { Date.today }
          must "be >= 2007-01-01" do |d|
            d >= Date.new(2007, 01, 01)
          end
        end
        has :end_date, { :kind => Date } do
          from String do |s|
            Date.parse(s)
          end
          from Array do |y,m,d|
            #p [:from, Array, y, m, d]
            Date.new(y, m, d)
          end
          from Integer do |jd|
            Doodle::Debug.d { [:converting_from, Integer, jd] }
            Date.new(*Date.send(:jd_to_civil, jd))
          end
          default { start_date }
        end
        must "have end_date >= start_date" do
          end_date >= start_date
        end
      end
    end
  
    it 'should not raise an exception if end_date >= start_date' do
      proc { DateRange.new('2007-01-01', '2007-01-02') }.should_not raise_error
    end
  
    it 'should raise an exception if end_date < start_date' do
      proc { DateRange.new('2007-01-02', '2007-01-01') }.should raise_error
    end

    it 'should raise an exception if end_date < start_date' do
      proc { DateRange.new('2007-01-01', '2007-01-01') }.should_not raise_error
    end

    it 'should have start_date kind == Date' do
      d = DateRange.new
      d.doodle.attributes[:start_date].kind == Date
    end

    it 'should have two validations' do
      d = DateRange.new
      d.doodle.attributes[:start_date].doodle.validations.size.should_be 2    
      d.doodle.attributes[:start_date].doodle.validations(false).size.should_be 2
    end

    it 'should have two conversions' do
      d = DateRange.new
      d.doodle.attributes[:start_date].doodle.conversions.size.should_be 3    
      d.doodle.attributes[:start_date].doodle.conversions(false).size.should_be 3
    end

    it 'should convert from Array' do
      d = DateRange.new [2007,01,01], [2007,01,02]
      d.start_date.should_be Date.new(2007,01,01)
      d.end_date.should_be Date.new(2007,01,02)
    end
  
    it 'should convert Integer representing Julian date to Date' do
      d = DateRange.new 2454428, 2454429
      d.start_date.should_be Date.new(2007,11,23)
      d.end_date.should_be Date.new(2007,11,24)
    end
  end
end
