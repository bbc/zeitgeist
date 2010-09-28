class Doodle
  module GetterSetter
    # define a getter_setter
    def define_getter_setter(name, params = { }, &block)
      module_eval {
        define_method name do |*args, &block|
          getter_setter(name.to_sym, *args, &block)
        end
        define_method "#{name}=" do |*args, &block|
          _setter(name.to_sym, *args, &block)
        end
      }
    end
  end
end
