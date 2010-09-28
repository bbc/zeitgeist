require File.dirname(__FILE__) + '/spec_helper.rb'
require 'date'

describe Doodle, 'conversions' do
  temporary_constant(:Foo) do
    before(:each) do
      class Foo < Doodle
        has :start do
          default { Date.today }
          from String do |s|
            Doodle::Debug.d { [:converting_from, String, s] }
            Date.parse(s)
          end
          from Integer do |jd|
            Doodle::Debug.d { [:converting_from, Integer, jd] }
            Date.new(*Date.send(:jd_to_civil, jd))
          end
        end
        from String do |s|
          Doodle::Debug.d { [:from, self, self.class] }
          new(:start => s)
        end
      end
    end

    it 'should have default date == today' do
      foo = Foo.new
      foo.start.should == Date.today
    end

    it 'should convert String to Date' do
      foo = Foo.new(:start => '2007-12-31')
      foo.start.should == Date.new(2007, 12, 31)
    end

    it 'should convert Integer representing Julian date to Date' do
      foo = Foo.new(:start => 2454428)
      foo.start.should == Date.new(2007, 11, 23)
    end

    it 'should allow from' do
      foo = Foo.from("2007-12-31")
      foo.start.should == Date.new(2007, 12, 31)
    end

    it 'should return class_conversions' do
      Foo.doodle.conversions.keys.should == [String]
    end

  end

end
