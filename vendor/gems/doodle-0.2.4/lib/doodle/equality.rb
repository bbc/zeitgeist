class Doodle
  module Equality
    # two doodles of the same class with the same attribute values are
    # considered equal
    def eql?(o)
      o.kind_of?(Doodle::Core) &&
        self.class == o.class &&
        doodle.key_values_without_defaults.all? { |k, v| o.respond_to?(k) && v.eql?(o.send(k)) }
      #         [self.class, doodle.key_values_without_defaults].eql?([o.class, o.doodle.key_values_without_defaults])
    end
    def ==(o)
      o.kind_of?(Doodle::Core) &&
        self.class == o.class &&
        doodle.key_values_without_defaults.all? { |k, v| o.respond_to?(k) && v == o.send(k) }
      #        [self.class, doodle.key_values_without_defaults] == [o.class, o.doodle.key_values_without_defaults]
    end
    def hash
      [self.class, doodle.key_values_without_defaults].hash
    end
  end
end

