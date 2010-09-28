require 'json'
require 'pp'

class Doodle
  module JSON
    # main one
    def self.parse(*a, &b)
      ::JSON.parse(*a, &b)
    end
    def self.method_missing(*a, &b)
      ::JSON.send(*a, &b)
    end
    module InstanceMethods
      def to_json(*a)
        # don't include default values
        values = doodle.key_values_without_defaults
        value_hash = Hash[*Doodle::Utils.flatten_first_level(values)]
        {
          'json_class'   => self.class.name,
          'data' => value_hash,
        }.to_json(*a)
      end
    end
    module ClassMethods
      def json_create(o)
        #pp [:json_create, o]
        const = Doodle::Utils.const_resolve(o['json_class'])
        const.new(o['data'])
      end
      def from_json(src)
        v = ::JSON::parse(src)
        if v.kind_of?(Hash)
          new(v)
        else
          v
        end
      end
    end
    def self.included(other)
      other.module_eval { include InstanceMethods }
      other.extend(ClassMethods)
    end
  end
  include Doodle::JSON
end
