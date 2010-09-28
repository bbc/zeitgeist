# -*- mode: ruby; -*-
# Sean O'Halpin, 2008-09-29

=begin

TODO:
- add file mode to filename (or have separate file type)
- use PathName?
- sort out lists of things (with types)
- apply match ~before~ from
  - add match to core doodle (as 'pattern' a la XMLSchema?)
- handle config files
- fix duplication

=end

require 'doodle'
require 'doodle/datatypes'
require 'time'
require 'date'
#require 'pp'

# note that all the datatypes within doodle do ... end blocks are
# doodle/datatypes - I then go on to define specialized option types
# with many of the same names but they are not the same - could be
# confusing :)

class Doodle
  # command line option handling DSL implemented using Doodle
  class App < Doodle
    class HelpExit < ::Exception
    end
    # specialised classes for handling attributes

    # replace the full directory path with ./ where appropriate
    def self.tidy_dir(path)
      path.to_s.gsub(Regexp.new("^#{ Regexp.escape(Dir.pwd) }/"), './')
    end

    # class representing a generic option
    class Option < Doodle::DoodleAttribute
      doodle do
        string :flag, :max => 1, :doc => "one character abbreviation" do
          init {
            mf = name.to_s[0].chr
            attrs = doodle_owner.doodle.attributes.map{ |k, v| v}
            chk_attrs = attrs.reject{ |v|
              v.name == name
            }
            # note: cannot check v.flag inside default clause because that
            # causes an infinite regress (yes, I found out the hard way! :)
            if chk_attrs.any?{|v|
                v.respond_to?(:flag) && v.flag == mf
              }
              ""
            else
              mf
            end
          }
        end
        integer :arity, :default => 1, :doc => "how many arguments are expected"
        has :values, :default => [], :doc => "valid values for this option"
        has :match, :default => nil, :doc => "regex to match against"
      end
    end
    # specialised Filename attribute
    # - :existing => true|false (default = false)
    class Filename < Option
      doodle do
        boolean :existing, :default => false, :doc => "set to true if file must exist"
        boolean :expand, :default => false, :doc => "set to true if you want to have the filename expanded"
      end
    end

    # regular expression for ISO datetime
    RX_ISODATETIME = /^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)? ?Z$/
    # regular expression for ISO date
    RX_ISODATE = /^\d{4}-\d{2}-\d{2}$/

    # App directives
    class << self
      public

      has :script_name, :default => File.basename($0), :doc => "base name of script"
      has :script_path, :default => File.expand_path(File.dirname($0)), :doc => "directory from which script is executed"
      has :doc, :default => $0, :doc => "documentation"
      has :usage, :doc => "usage description" do
        default { "./#{script_name} #{required_args.map{ |a| %[-#{ a.flag } #{format_kind(a.kind)}]}.join(' ')}" + ((required_args.size - doodle.attributes.size) > 0 ? " [OPTIONS]" : '') }
      end
      has :examples, :collect => :example, :doc => "example(s) of use"

      # specify that this argument is required
      def required
        @optional = false
      end
      # specify that this argument is optional
      def optional
        @optional = true
      end
      # returns true if argument is optional, false otherwise
      def optional?
        instance_variable_defined?("@optional") ? @optional : false
      end
      # return list of required attributes
      def required_args
        doodle.attributes.select{ |k, v| v.required?}.map{ |k,v| v}
      end
      alias :options :optional

      # the generic option - can be any type
      def option(*args, &block)
        #p [:option, args, :optional, optional?]
        key_values, args = args.partition{ |x| x.kind_of?(Hash)}
        key_values = key_values.inject({ }){ |hash, kv| hash.merge(kv)}

        errors = []

        # handle optional/required flipflop
        if optional?
          required = { :default => nil }
          if key_values.delete(:required)
            if key_values.key?(:optional)
              errors << "Can't specify both :required and :optional"
            end
            if key_values.key?(:default)
              errors << "Can't specify both :required and :default"
            end
            required = { }
          elsif key_values.delete(:optional) && !key_values.key?(:default)
            required = { :default => nil }
          end
        else
          key_values.delete(:required)
          required = { }
        end
        args = [{ :using => Option }.merge(required).merge(key_values), *args]
        da = has(*args, &block)
        if errors.size > 0
          raise ArgumentError, "#{da.name}: #{errors.join(', ')}", [caller[-1]]
        end
        da.instance_eval do
          #p [:checking_values, values, values.class]
          if da.values.kind_of?(Range)
            must "be in range #{da.values}" do |s|
              da.values.include?(s)
            end
          elsif da.values.respond_to?(:size) && da.values.size > 0
            must "be one of #{da.values.join(', ')}" do |s|
              da.values.include?(s)
            end
          end
          if da.match
            must "match pattern #{da.match.inspect}" do |s|
              #p [:matching, s, da.match.inspect]
              s.to_s =~ da.match
            end
          end
        end
        da
      end

      # SPECIFIC OPTION TYPES

      # expect a string
      def string(*args, &block)
        args = [{ :using => Option, :kind => String }, *args]
        da = option(*args, &block)
      end

      # expect a symbol (and convert from String)
      def symbol(*args, &block)
        args = [{ :using => Option, :kind => Symbol }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            s.to_sym
          end
        end
      end

      # expect a filename - set <tt>:existing => true</tt> to specify that the file must exist
      #   filename :input, :existing => true, :flag => "i", :doc => "input file name"
      def filename(*args, &block)
        args = [{ :using => Filename, :kind => String }, *args ]
        da = option(*args, &block)
        da.instance_eval do
          if da.existing
            must "exist" do |s|
              File.exist?(s)
            end
          end
          if da.expand
            from String do |s|
              File.expand_path(s)
            end
          end
        end
      end

      # expect an on/off flag, e.g. -b
      # - doesn't take any arguments (mere presence sets it to true)
      # - booleans are false by default
      def boolean(*args, &block)
        args = [{ :using => Option, :default => false, :arity => 0}, *args]
        da = option(*args, &block)
        da.instance_eval do
          kind FalseClass, TrueClass
          from NilClass do
            false
          end
          from Numeric do |n|
            n == 0 ? false : true
          end
          from String do |s|
            case s
            when "on", "true", "yes", "1"
              true
            when "off", "false", "no", "0"
              false
            else
              raise Doodle::ValidationError, "unknown value for boolean: #{s}"
            end
          end
        end
      end

      # whole number, e.g. -n 10
      # - you can use, e.g. :values => [1,2,3] or :values => (0..99) to restrict the range of valid values
      def integer(*args, &block)
        args = [{ :using => Option, :kind => Integer }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            s =~ /^\d+$/ or raise "must be a whole number"
            s.to_i
          end
        end
      end

      # date: -d 2008-09-28
      def date(*args, &block)
        args = [{ :using => Option, :kind => Date, :doc => "ISO format date, e.g. 2008-09-28" }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            Date.parse(s)
          end
        end
      end

      # time: -t 2008-09-28T18:00:00
      def time(*args, &block)
        args = [{ :using => Option, :kind => Time, :doc => "quasi-ISO format localtime without timezone, e.g. 2008-09-28T18:00:00" }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            Time.parse(s)
          end
        end
      end

      # utctime: -u 2008-09-28T21:41:29Z
      def utctime(*args, &block)
        args = [{ :using => Option, :kind => Time, :doc => "ISO format UTC time, e.g. 2008-09-28T18:00:00Z" }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            if s !~ RX_ISODATETIME
              #p [:not_isodatetime]
              if s !~ RX_ISODATE
                #p [:not_isodate]
                raise ArgumentError, "datetime must be in ISO format (YYYY-MM-DDTHH:MM:SS, e.g. #{Time.now.utc.xmlschema})"
              else
                #p [:isodate]
                s = s + "T00:00:00Z"
              end
            else
              #p [:isodatetime]
            end
            Time.parse(s)
          end
        end
      end

      # utcdate: -d 2008-09-28
      def utcdate(*args, &block)
        args = [{ :using => Option, :kind => Date }, *args]
        da = option(*args, &block)
        da.instance_eval do
          from String do |s|
            if s !~ RX_ISODATETIME
              #p [args, :not_isodatetime]
              if s !~ RX_ISODATE
                #p [:not_isodate]
                raise ArgumentError, "date must be in ISO format (YYYY-MM-DDTHH:MM:SS, e.g. #{Time.now.utc.xmlschema})"
              else
                #p [args, :isodate]
                s = s + "T00:00:00Z"
              end
            else
              #p [args, :isodatetime]
            end
            Date.parse(s)
          end
        end
      end

      # use this to include 'standard' flags: help (-h, --help), verbose (-v, --verbose) and debug (-d, --debug)
      def std_flags
        # FIXME: this is bogus
        m = method(:help_text)
        boolean :help, :flag => "h", :doc => "display this help"
        boolean :verbose, :flag => "v", :doc => "verbose output"
        boolean :debug, :flag => "D", :doc => "turn on debugging"
      end

      has :exit_status, :default => 0

      # call App.run to start your application (calls instance.run)
      def run(argv = ARGV)
        begin
          # cheating
          if argv.include?('-h') or argv.include?('--help')
            puts help_text
          else
            app = from_argv(argv)
            app.run
          end
        rescue Exception => e
          if exit_status == 0
            exit_status 1
          end
          puts "\nERROR: #{e}"
        ensure
          exit(exit_status)
        end
      end

      private

      # helpers
      def flag_to_attribute(flag)
        a = doodle.attributes.select do |key, attr|
          (key.to_s == flag.to_s) || (attr.respond_to?(:flag) && attr.flag.to_s == flag.to_s)
        end
        if a.size == 0
          raise ArgumentError, "Unknown option: #{flag}"
        elsif a.size > 1
          #raise ArgumentError, "More than one option matches: #{flag}"
        end
        a.first
      end

      def key_value(arg, argv)
        value = nil
        if arg[0..0] == "-"
          # got flag
          #p [:a, 1, arg]
          if arg[1..1] == "-"
            # got --flag
            # --key value
            key = arg[2..-1]
            #p [:a, 2, arg, key]
            if key == ""
              key = "--"
            end
          else
            key = arg[1].chr
            #p [:a, 4, key]
            if arg[2]
              # -kvalue
              value = arg[2..-1]
              #p [:a, 5, key, value]
            end
          end
          pkey, attr = flag_to_attribute(key)
          if pkey.nil?
            raise Exception, "Internal error: #{key} does not match attribute"
          end
          #p [:flag_to_attribute, key, value, pkey, attr]
          if value.nil?
            if attr.arity == 0
              value = true
            else
              #p [:args, 5, :getting_args, attr.arity]
              value = []
              1.upto(attr.arity) do
                a = argv.shift
                break if a.nil?
                #p [:a, 6, key, value]
                if a =~ /^-/
                  # got a switch - break? (what should happen here?)
                  #p [:a, 7, key, value]
                  argv.unshift a
                  break
                else
                  value << a
                end
              end
              if attr.arity == 1
                value = value.first
              end
            end
          end
          if key.size == 1
            #p [:finding, key]
            #p [:found, pkey, attr]
            key = pkey.to_s
          end
        end
        [key, value]
      end

      def params_args(argv)
        argv = argv.dup
        params = { }
        args = []
        while arg = argv.shift
          key, value = key_value(arg, argv)
          if key.nil?
            args << arg
          else
            #p [:setting, key,  value]
            params[key] = value
          end
        end
        [params, args]
      end

      def from_argv(argv)
        params, args = params_args(argv)
        args << params
        new(*args)
      end

      def format_values(values)
        case values
        when Array
          values.map{ |s| s.to_s }.join(', ')
        when Range
          values.inspect
        else
          values.inspect
        end
      end

      def format_doc(attr)
        #p [:doc, attr.doc]
        doc = attr.doc
        if doc.kind_of?(Doodle::DeferredBlock)
          doc = doc.block
        end
        if doc.kind_of?(Proc)
          doc = attr.instance_eval(&doc)
        end
        if doc.respond_to?(:call)
          doc = doc.call
        end
        doc = doc.to_s
        if attr.respond_to?(:values) && (attr.values.kind_of?(Range) || attr.values.size > 0)
          doc = "#{doc} [#{format_values(attr.values)}]"
        end
        doc
      end

      def format_kind(kind)
        if (kind & [TrueClass, FalseClass, NilClass]).size > 0
          "Boolean"
        else
          kind.map{ |k| k.to_s }.join(', ')
        end.upcase
      end

      def help_attributes
        options, args = doodle.attributes.partition { |key, attr| attr.respond_to?(:flag)}
        args = args.map { |key, attr|
          [
           '',
           '',
           format_doc(attr),
           attr.required?,
           format_kind(attr.kind),
          ]
        }
        options = options.map { |key, attr|
          [
           "--#{key}",
           attr.flag.to_s.size > 0 ? "-#{attr.flag}," : '',
           format_doc(attr),
           attr.required?,
           format_kind(attr.kind),
          ]
        }
        args + options
      end

      public

      # defines the help text displayed when option --help passed
      def help_text
        format_block = proc {|key, flag, doc, required, kind|
          sprintf("  %-3s %-14s %-10s %s %s", flag, key, kind, doc, required ? '(REQUIRED)' : '')
        }
        required, options = help_attributes.partition{ |a| a[3]}
        [
         self.doc,
         "\n",
         self.usage ? ["Usage: " + self.usage, "\n"] : [],
         required.size > 0 ? ["Required args:", required.map(&format_block), "\n"] : [],
         options.size > 0 ? ["Options:", options.map(&format_block), "\n"] : [],
         (self.examples && self.examples.size > 0) ? "Examples:\n" + "  " + [self.examples].flatten.join("\n  ") : [],
        ]
      end
    end
  end
end
