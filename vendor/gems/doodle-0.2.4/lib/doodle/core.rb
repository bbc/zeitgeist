class Doodle
  module ClassMethods
    # provide somewhere to hold thread-specific context information
    # (I'm claiming the :doodle_xxx namespace)
    def context
      Thread.current[:doodle_context] ||= []
    end
    def parent
      context[-1]
    end
  end

  extend ClassMethods

  # Place to hold refs to built-in classes that need special handling
  module BuiltIns
    BUILTINS = [String, Hash, Array]
  end

  # Include Doodle::Core if you want to derive from another class
  # but still get Doodle goodness in your class (including Factory
  # methods).
  module Core
    module ModuleMethods
      def included(other)
        super
        other.module_eval {
          # FIXME: this is getting a bit arbitrary
          include Equality
          include Comparable
          include Inherited
          inherit BaseMethods
        }
      end
    end
    extend ModuleMethods
  end

  include Core

end

