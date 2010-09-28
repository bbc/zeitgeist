$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'date'
require 'doodle'
require 'doodle/utils' # for try

class DateRange < Doodle 
  has :start_date, :kind => Date do
    default { Date.today }
    from String do |s|
      Date.parse(s)
    end
    must "be >= 2000-01-01" do |d|
      d >= Date.parse('2000-01-01')
    end
  end
  has :end_date do
    default { start_date }
    from String do |s|
      Date.parse(s)
    end
  end
  must 'have end_date >= start_date' do
    end_date >= start_date
  end
  from String do |s|
    m = /(\d{4}-\d{2}-\d{2})\s*(?:to|-|\s)\s*(\d{4}-\d{2}-\d{2})/.match(s)
    if m
      self.new(*m.captures)
    else
      raise Exception, "Cannot parse date: '#{s}'"
    end
  end
end

dr = DateRange.new '2007-12-31', '2008-01-01'
dr.start_date                   # =>
dr.end_date                     # =>

dr = DateRange '2007-12-31', '2008-01-01'
dr.start_date                   # =>
dr.end_date                     # =>

dr = DateRange :start_date => '2007-12-31', :end_date => '2008-01-01'
dr.start_date                   # =>
dr.end_date                     # =>

dr = DateRange do
  start_date '2007-12-31'
  end_date '2008-01-01'
end
dr.start_date                   # =>
dr.end_date                     # =>


dr = DateRange.from '2007-01-01 to 2008-12-31'
dr.start_date                   # =>
dr.end_date                     # =>

dr = DateRange.from '2007-01-01 2007-12-31'
dr.start_date                   # =>
dr.end_date                     # =>

p try {
  dr = DateRange.from 'Hello World'
  dr.start_date                   # =>
  dr.end_date                     # =>
}

p try {
  dr = DateRange '2008-01-01', '2007-12-31' 
  dr.start_date                   # =>
  dr.end_date                     # =>
}
