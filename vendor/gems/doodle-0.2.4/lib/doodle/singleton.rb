class Doodle
  # provides more direct access to the singleton class and a way to
  # treat singletons, Modules and Classes equally in a meta context
  module Singleton
    # return the 'singleton class' of an object, optionally executing
    # a block argument in the (module/class) context of that object
    def singleton_class(&block)
      sc = class << self; self; end
      sc.module_eval(&block) if block_given?
      sc
    end
    # evaluate in class context of self, whether Class, Module or singleton
    def sc_eval(*args, &block)
      if self.kind_of?(Module)
        klass = self
      else
        klass = self.singleton_class
      end
      klass.module_eval(*args, &block)
    end
  end

end
