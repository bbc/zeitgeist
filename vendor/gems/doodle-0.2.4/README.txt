= doodle

* Homepage: http://doodle.rubyforge.org
* Github repo: http://github.com/seanohalpin/doodle/tree/master
* Lighthouse issue tracker: http://seanohalpin.lighthouseapp.com/projects/26673-doodle/overview

== DESCRIPTION:

Doodle is a Ruby library for simplifying the definition of Ruby
classes by making attributes and their properties more declarative.

Doodle is eco-friendly: it does not globally modify Object, Class or
Module, nor does it pollute instances with its own instance variables
(i.e. it plays nice with yaml).

Doodle has been tested with Ruby 1.8.6, 1.9.1 and JRuby 1.1. It has
not yet been tested with Rubinius.

Please feel free to post bug reports, feature requests, and any
comments or discussion topics to the doodle Google group:
http://groups.google.com/group/ruby-doodle

== FEATURES:

* initialization
  * using positional arguments
  * with named arguments
  * by block
* defaults
* initial values
* validation at attribute and class levels
* conversions for attributes and classes
* collectors to help in defining simple DSLs
* works for classes, instances and singletons

== SYNOPSIS:

=== Example 1

  require 'rubygems'
  require 'date'
  require 'doodle'

  class DateRange < Doodle
    has :start_date do
      default { Date.today }
    end
    has :end_date do
      default { start_date }
    end
  end

  dr = DateRange.new
  dr.start_date                   # => #<Date: 4909159/2,0,2299161>
  dr.end_date                     # => #<Date: 4909159/2,0,2299161>

=== Example 2

  require 'rubygems'
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
  dr.start_date                   # => #<Date: 4908931/2,0,2299161>
  dr.end_date                     # => #<Date: 4908933/2,0,2299161>

  dr = DateRange '2007-12-31', '2008-01-01'
  dr.start_date                   # => #<Date: 4908931/2,0,2299161>
  dr.end_date                     # => #<Date: 4908933/2,0,2299161>

  dr = DateRange :start_date => '2007-12-31', :end_date => '2008-01-01'
  dr.start_date                   # => #<Date: 4908931/2,0,2299161>
  dr.end_date                     # => #<Date: 4908933/2,0,2299161>

  dr = DateRange do
    start_date '2007-12-31'
    end_date '2008-01-01'
  end
  dr.start_date                   # => #<Date: 4908931/2,0,2299161>
  dr.end_date                     # => #<Date: 4908933/2,0,2299161>


  dr = DateRange.from '2007-01-01 to 2008-12-31'
  dr.start_date                   # => #<Date: 4908203/2,0,2299161>
  dr.end_date                     # => #<Date: 4909663/2,0,2299161>

  dr = DateRange.from '2007-01-01 2007-12-31'
  dr.start_date                   # => #<Date: 4908203/2,0,2299161>
  dr.end_date                     # => #<Date: 4908931/2,0,2299161>

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
  # >> #<Doodle::ConversionError: Cannot parse date: 'Hello World'>
  # >> #<Doodle::ValidationError: DateRange must have end_date >= start_date>

== INSTALL:

* Linux/Mac OS X

  $ sudo gem install doodle

* Windows

  C:\> gem install doodle

== LICENSE:

(The MIT License)

Copyright (c) 2007-2009 Sean O'Halpin

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
