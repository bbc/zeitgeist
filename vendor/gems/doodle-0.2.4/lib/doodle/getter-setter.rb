class Doodle
  module GetterSetter
    # either get an attribute value (if no args given) or set it
    # (using args and/or block)
    # FIXME: move
    def getter_setter(name, *args, &block)
      #p [:getter_setter, name]
      name = name.to_sym
      if block_given? || args.size > 0
        #!p [:getter_setter, :setter, name, *args]
        _setter(name, *args, &block)
      else
        #!p [:getter_setter, :getter, name]
        _getter(name)
      end
    end
    private :getter_setter

    # get an attribute by name - return default if not otherwise defined
    # FIXME: init deferred blocks are not getting resolved in all cases
    def _getter(name, &block)
      begin
        Doodle::Debug.d { [:_getter, name] }
        ivar = "@#{name}"
        if instance_variable_defined?(ivar)
          Doodle::Debug.d { [:_getter, :instance_variable_defined, name, ivar, instance_variable_get(ivar)] }
          instance_variable_get(ivar)
        else
          # handle default
          # Note: use :init => value to cover cases where defaults don't work
          # (e.g. arrays that disappear when you go out of scope)
          att = __doodle__.lookup_attribute(name)
          # special case for class/singleton :init
          if att && att.optional?
            optional_value = att.init_defined? ? att.init : att.default
            Doodle::Debug.d { [:optional_value, name, optional_value] }
            case optional_value
            when DeferredBlock
              Doodle::Debug.d { [:deferred_block, name] }
              v = instance_eval(&optional_value.block)
            when Proc
              Doodle::Debug.d { [:proc] }
              v = instance_eval(&optional_value)
            else
              Doodle::Debug.d { [:optional_value, name, optional_value] }
              v = optional_value
            end
            Doodle::Debug.d { [:value, name, v] }
            if att.init_defined?
              Doodle::Debug.d { [:init_defined, name] }
              v = _setter(name, v)
            end
            v
          else
            # This is an internal error (i.e. shouldn't happen)
            __doodle__.handle_error name, NoDefaultError, "'#{name}' has no default defined", Doodle::Utils.doodle_caller
          end
        end
      rescue Object => e
        __doodle__.handle_error name, e, e.to_s, Doodle::Utils.doodle_caller(e)
      end
    end
    private :_getter

    def after_update(*args)
    end

    # set an instance variable by symbolic name and call after_update if changed
    def ivar_set(name, *args)
      ivar = "@#{name}"
      if instance_variable_defined?(ivar)
        old_value = instance_variable_get(ivar)
      else
        old_value = nil
      end
      #p [:ivar_set, 1, name, old_value, :args, *args]
      instance_variable_set(ivar, *args)
      new_value = instance_variable_get(ivar)
      #p [:ivar_set, 1, name, old_value, :new_value, new_value, new_value.object_id, :args, *args]
      if new_value != old_value
        #pp [Doodle, :after_update, { :instance => self, :name => name, :old_value => old_value, :new_value => new_value }]
        after_update :instance => self, :name => name, :old_value => old_value, :new_value => new_value
      end
      new_value
    end
    private :ivar_set

    # set an attribute by name - apply validation if defined
    # FIXME: move
    def _setter(name, *args, &block)
      Doodle::Debug.d { [:_setter, 1, name, args] }
      #p [:_setter, name, *args]
      att = __doodle__.lookup_attribute(name)
      Doodle::Debug.d { [:_setter, 2, :att, att] }
      if att && __doodle__.validation_on && att.readonly
        Doodle::Debug.d { [:_setter, 3] }
        raise Doodle::ReadOnlyError, "Trying to set a readonly attribute: #{att.name}", Doodle::Utils.doodle_caller
      end
      if block_given?
        Doodle::Debug.d { [:_setter, 4] }
        # if a class has been defined, let's assume it can take a
        # block initializer (test that it's a Doodle or Proc)
        if att.kind && !att.abstract && klass = att.kind.first
          Doodle::Debug.d { [:_setter, 5] }
          if [Doodle, Proc].any?{ |c| klass <= c }
            # p [:_setter, '# 1 converting arg to value with kind ' + klass.to_s]
            Doodle::Debug.d { [:_setter, 6] }
            args = [klass.new(*args, &block)]
          else
            Doodle::Debug.d { [:_setter, 7] }
            __doodle__.handle_error att.name, ArgumentError, "#{klass} #{att.name} does not take a block initializer", Doodle::Utils.doodle_caller
          end
        else
          Doodle::Debug.d { [:_setter, 8] }
          # this is used by init do ... block
          args.unshift(DeferredBlock.new(block))
        end
      end
      Doodle::Debug.d { [:_setter, 9] }
      if att
        Doodle::Debug.d { [:_setter, 10] }
        if att.kind && !att.abstract && klass = att.kind.first
          Doodle::Debug.d { [:_setter, 11, :att_kind, klass] }
          if !args.first.kind_of?(klass) && [Doodle].any?{ |c| klass <= c }
            Doodle::Debug.d { [:_setter, 12] }
            #p [:_setter, "#2 converting arg #{att.name} to value with kind #{klass.to_s}"]
            #p [:_setter, args]
            begin
              # try conversion if only one argument and conversion exists
              conversion = att.__doodle__.conversions[args.first.class]
              Doodle::Debug.d { [:_setter, 12.1, name, att.__doodle__.conversions.keys, conversion, args.first, args.first.class ] }
              if args.size == 1 && conversion
                Doodle::Debug.d { [:_setter, 12.2, :trying_conversion ] }
                args = att.convert(self, *args)
              else
                Doodle::Debug.d { [:_setter, 12.3, :initialize_using_first_kind, klass, 13] }
                args = [klass.new(*args, &block)]
              end
            rescue Object => e
              Doodle::Debug.d { [:_setter, 14] }
              __doodle__.handle_error att.name, e.class, e.to_s, Doodle::Utils.doodle_caller(e)
            end
          end
        else
          Doodle::Debug.d { [:_setter, 10.1, :abstract, att.abstract] }
        end
        Doodle::Debug.d { [:_setter, 15] }
        #p [:_setter, :got_att1, name, args.map{ |x| x.object_id }, *args]
        v = ivar_set(name, att.validate(self, *args))

        #p [:_setter, :got_att2, name, ivar, :value, v]
        #v = instance_variable_set(ivar, *args)
      else
        Doodle::Debug.d { [:_setter, 16] }
        #p [:_setter, :no_att, name, *args]
        ##DBG: Doodle::Debug.d { [:_setter, "no attribute"] }
        v = ivar_set(name, *args)
      end
      Doodle::Debug.d { [:_setter, 17, v] }
      validate!(false)
      v
    end
    private :_setter

    if RUBY_VERSION < '1.8.7'
      # define a getter_setter
      # fixme: move
      def define_getter_setter(name, params = { }, &block)
        # need to use string eval because passing block
        sc_eval <<-EOT, __FILE__, __LINE__
          def #{name}(*args, &block)
            Doodle::Debug.d { [:SETTER, :#{name}, args, block ] }
            getter_setter(:#{name}, *args, &block)
          end
        EOT
        sc_eval <<-EOT, __FILE__, __LINE__
          def #{name}=(*args, &block)
            Doodle::Debug.d { [:SETTER, :#{name}=, args ] }
            _setter(:#{name}, *args)
          end
        EOT
      end
    else
      require 'doodle/define-getter-setter1.9'
    end
    private :define_getter_setter

  end
end
