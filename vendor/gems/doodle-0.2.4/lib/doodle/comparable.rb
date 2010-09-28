class Doodle
  # doodles are compared (sorted) on values
  module Comparable
    def <=>(o)
      doodle.values <=> o.doodle.values
    end
  end
end
