class Doodle
  # implements the #doodle directive
  class DataTypeHolder
    attr_accessor :klass

    def initialize(klass, &block)
      @klass = klass
      instance_eval(&block) if block_given?
    end

    def define(name, params, block, type_params, &type_block)
      @klass.class_eval {
        td = has(name, type_params.merge(params), &type_block)
        td.instance_eval(&block) if block
        td
      }
    end

    def has(*args, &block)
      @klass.class_eval { has(*args, &block) }
    end

    def must(*args, &block)
      @klass.class_eval { must(*args, &block) }
    end

    def from(*args, &block)
      @klass.class_eval { from(*args, &block) }
    end

    def arg_order(*args, &block)
      @klass.class_eval { arg_order(*args, &block) }
    end

    def doc(*args, &block)
      @klass.class_eval { doc(*args, &block) }
    end
  end
end
