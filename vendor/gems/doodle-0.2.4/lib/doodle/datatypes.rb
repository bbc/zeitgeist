base_path = File.dirname(__FILE__)
require 'doodle'
require 'date'
require 'time'
require 'uri'
require File.join(base_path, 'rfc822')

# note: this doesn't have to be in Doodle namespace
class Doodle
  module DataTypes
    class DataType < Doodle::DoodleAttribute
      doodle do
        has :values, :default => [], :doc => "valid values for this option"
        has :match, :default => nil, :doc => "regex to match against"
      end
    end
    def datatype(name, params, block, type_params, &type_block)
      define name, params, block, { :using => DataType }.merge(type_params) do
        #p [:self, __doodle__.__inspect__]
        #p [:checking_values, values, values.class]
        if respond_to?(:values)
          if values.kind_of?(Range)
            must "be in range #{values}" do |s|
              values.include?(s)
            end
            # array of values
          elsif values.respond_to?(:size) && values.size > 0
            must "be one of #{values.join(', ')}" do |s|
              values.include?(s)
            end
          end
        end
        if respond_to?(:match) && match
          must "match pattern #{match.inspect}" do |s|
            #p [:matching, s, da.match.inspect]
            s.to_s =~ match
          end
        end
        instance_eval(&type_block) if type_block
      end
    end

    def integer(name, params = { }, &block)
      params = params.dup
      if params.key?(:max)
        max = params.delete(:max)
      end
      if params.key?(:min)
        min = params.delete(:min)
      end
      datatype name, params, block, { :kind => Integer } do
        from Float do |n|
          n.to_i
        end
        from String do |n|
          n =~ /[0-9]+(.[0-9]+)?/ or raise ArgumentError, "#{name} must be numeric", [caller[-1]]
          n.to_i
        end
        if max
          must "be <= #{max}" do |s|
            s <= max
          end
        end
        if min
          must "be >= #{min}" do |s|
            s >= max
          end
        end
      end
    end

    def boolean(name, params = { }, &block)
      datatype name, params, block, { :default => true } do
        must "be true or false" do |v|
          [true, false].include?(v)
        end
        from NilClass do |v|
          false
        end
        from Integer do |v|
          v == 0 ? false : true
        end
        from String, Symbol do |v|
          case v.to_s
          when /^(yes|true|on|1)$/
            true
          when /^(no|false|off|0)$/
            false
          else
            # empty string "" is false by this definition
            !v.empty?
          end
        end
      end
    end

    def symbol(name, params = { }, &block)
      datatype name, params, block, { :kind => Symbol } do
        from String do |s|
          s.to_sym
        end
      end
    end

    def string(name, params = { }, &block)
      # must extract non-standard attributes before processing with
      # datatype otherwise causes UnknownAttribute error in Attribute definition
      params = params.dup
      if params.key?(:max)
        max = params.delete(:max)
      end
      if params.key?(:min)
        min = params.delete(:min)
      end
      if params.key?(:size)
        size = params.delete(:size)
        # size should be a Range
        size.kind_of?(Range) or raise ArgumentError, "#{name}: size should be a Range", [caller[-1]]
      end
      datatype name, params, block, { :kind => String } do
        from String do |s|
          s
        end
        from Integer do |i|
          i.to_s
        end
        from Symbol do |s|
          s.to_s
        end
        if max
          must "be <= #{max} characters" do |s|
            s.size <= max
          end
        end
        if min
          must "be >= #{min} characters" do |s|
            s.size >= min
          end
        end
        if size
          must "have size of #{size} characters" do |s|
            size.include?(s.size)
          end
        end
      end
    end

    module DecorateURI
      def to_yaml(*opts)
        to_s.to_yaml(*opts)
      end
    end

    def uri(name, params = { }, &block)
      datatype name, params, block, { :kind => URI } do
        from String do |s|
          URI.parse(s).extend(Doodle::DataTypes::DecorateURI)
        end
        from URI do |u|
          u.extend(Doodle::DataTypes::DecorateURI)
        end
      end
    end

    def email(name, params = { }, &block)
      # for max length, see http://www.imc.org/ietf-fax/archive2/msg01578.html
      # 384 = 128+1+255
      string(name, { :max => 384 }.merge(params), &block).instance_eval do
        must "be valid email address" do |s|
          s =~ RFC822::EmailAddress
        end
      end
    end

    def date(name, params = { }, &block)
      datatype name, params, block, { :kind => Date } do
        from String do |s|
          Date.parse(s)
        end
        from Array do |y,m,d|
          Date.new(y, m, d)
        end
        from Integer do |jd|
          Date.new(*Date.send(:jd_to_civil, jd))
        end
      end
    end

    # defaults to UTC if passed an array
    # use :timezone => :local if you want local time
    def time(name, params = { }, &block)
      params = params.dup
      timezone_method = params.delete(:timezone) || :utc
      if timezone_method == :local
        timezone_method = :mktime
      end
      datatype name, params, block, { :kind => Time } do
        from String do |s|
          Time.parse(s)
        end
        from Array do |args|
          Time.send(timezone_method, *args)
        end
        # seconds since Thu Jan 01 00:00:00 UTC 1970
        from Integer do |epoch_seconds|
          Time.at(epoch_seconds)
        end
      end
    end

    RX_ISODATE = /^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2})?(\.\d+)?)?(( ?Z)|([+-]\d{2}:\d{2}))?$/

    def utc(name, params = { }, &block)
      da = time( name, { :kind => Time }.merge(params))
      da.instance_eval do
        # override time from String
        from String do |s|
          if s !~ RX_ISODATE
            raise ArgumentError, "date must be in ISO format yyyy-mm-ddThh:mm:ss (e.g. #{Time.now.utc.xmlschema})"
          end
          Time.parse(s)
        end
      end
      da.instance_eval(&block) if block_given?
      da
    end

    def version(name, params = { }, &block)
      datatype name, params, block, { :kind => String } do
        must "be of form n.n.n" do |str|
          str =~ /^\d+\.\d+.\d+$/
        end
        from Array do |a|
          a.size == 3 or raise ArgumentError, "#{name}: version array argument must contain exactly 3 elements", [caller[-1]]
          a.join('.')
        end
      end
    end

    def host_address(name, params = { }, &block)
      datatype name, params, block, { :kind => String } do
        must "be a hostname or dotted quad of form n.n.n.n" do |str|
          if str =~ /^(\d+\.){1,}\d+$/
            if str =~ /^(\d+\.){3}\d+$/
              true
            else
              __doodle__.handle_error name, ArgumentError, "'#{str[0..20]}' is not a dotted quad", [caller[-1]]
            end
          else
            begin
              URI.parse(str)
            rescue => e
              __doodle__.handle_error name, e.class, e.to_s, [caller[-1]]
            end
            true
          end
        end
        from Array do |a|
          a.size == 4 or raise ArgumentError, "#{name}: version array argument must contain exactly 3 elements", [caller[-1]]
          a.join('.')
        end
      end
    end
    alias :dotted_quad :host_address

    def list(name, params = { }, &block)
      if name.kind_of?(Class)
        params[:collect] = name
        name = Doodle::Utils.pluralize(Doodle::Utils.snake_case(name))
      end
      raise ArgumentError, "#{name} must specify what to :collect", [caller[-1]] if !params.key?(:collect)
      datatype name, params, block, { :using => Doodle::AppendableAttribute }
    end

    def dictionary(name, params = { }, &block)
      if name.kind_of?(Class)
        params[:collect] = name
        name = Doodle::Utils.pluralize(Doodle::Utils.snake_case(name))
      end
      raise ArgumentError, "#{name} must specify what to :collect", [caller[-1]] if !params.key?(:collect)
      datatype name, params, block, { :using => Doodle::KeyedAttribute }
    end
  end
end

# tell doodle to incorporate the datatypes
Doodle.datatypes Doodle::DataTypes

