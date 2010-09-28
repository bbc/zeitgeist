class Doodle

  # match a class signature
  def self.match_sig(desired, actual)
    actual.zip(desired).all?{ |a, d| a <= d}
  end

  # the core module of Doodle - however, to get most facilities
  # provided by Doodle without inheriting from Doodle, include
  # Doodle::Core, not this module
  module BaseMethods
    include Singleton
    include SmokeAndMirrors
    include ToHash
    include ModMarshal
    include GetterSetter
    include ValidationHelper
    include ConversionHelper

    # NOTE: can't do either of these

    #     include Equality
    #     include Comparable

    #     def self.included(other)
    #       other.module_eval {
    #         include Equality
    #         include Comparable
    #       }
    #     end

    # this is the only way to get at internal values. Note: this is
    # initialized on the fly rather than in #initialize because
    # classes and singletons don't call #initialize
    def __doodle__
      @__doodle__ ||= DoodleInfo.new(self)
    end
    protected :__doodle__

    # set up global datatypes
    def datatypes(*mods)
      mods.each do |mod|
        DataTypeHolder.class_eval { include mod }
      end
    end

    # vector through this method to get to doodle info or enable global
    # datatypes and provide an interface that allows you to add your own
    # datatypes to this declaration
    def doodle(*mods, &block)
      if mods.size == 0 && !block_given?
        __doodle__
      else
        dh = Doodle::DataTypeHolder.new(self)
        mods.each do |mod|
          dh.extend(mod)
        end
        dh.instance_eval(&block)
      end
    end

    # +doc+ add docs to doodle class or attribute
    def doc(*args, &block)
      if args.size > 0
        @doc = *args
      else
        @doc
      end
    end
    alias :doc= :doc

    # +has+ is an extended +attr_accessor+
    #
    # simple usage - just like +attr_accessor+:
    #
    #  class Event
    #    has :date
    #  end
    #
    # set default value:
    #
    #  class Event
    #    has :date, :default => Date.today
    #  end
    #
    # set lazily evaluated default value:
    #
    #  class Event
    #    has :date do
    #      default { Date.today }
    #    end
    #  end
    #
    def has(*args, &block)
      Doodle::Debug.d { [:args, self, self.class, args] }
      params = DoodleAttribute.params_from_args(self, *args)
      Doodle::Debug.d { [:params, self, params] }
      # get specialized attribute class or use default
      attribute_class = params.delete(:using) || DoodleAttribute

      # could this be handled in DoodleAttribute?
      # define getter setter before setting up attribute
      define_getter_setter params[:name], params, &block
      #p [:attribute, attribute_class, params]
      attr = __doodle__.local_attributes[params[:name]] = attribute_class.new(params, &block)

      # FIXME: not sure this is really the right place for this (but
      # right now the only place I can get it to work :)
      if from_defined = params[:from]
        from_defined.each do |k, v|
          Doodle::Debug.d { [:defining, self, k, v]}
          attr.instance_eval { from k, &v }
        end
      end

      if must_defined = params[:must]
        must_defined.each do |k, v|
          attr.instance_eval { must k, &v }
        end
      end

      attr
    end

    # define order for positional arguments
    def arg_order(*args)
      if args.size > 0
        begin
          args = args.uniq
          args.each do |x|
            __doodle__.handle_error :arg_order, ArgumentError, "#{x} not a Symbol", Doodle::Utils.doodle_caller if !(x.class <= Symbol)
            __doodle__.handle_error :arg_order, NameError, "#{x} not an attribute name", Doodle::Utils.doodle_caller if !doodle.attributes.keys.include?(x)
          end
          __doodle__.arg_order = args
        rescue Exception => e
          __doodle__.handle_error :arg_order, InvalidOrderError, e.to_s, Doodle::Utils.doodle_caller(e)
        end
      else
        __doodle__.arg_order + (__doodle__.attributes.keys - __doodle__.arg_order)
      end
    end

    # return true if instance variable +name+ defined
    # FIXME: move
    def ivar_defined?(name)
      instance_variable_defined?("@#{name}")
    end
    private :ivar_defined?

    # get an instance variable by symbolic name
    def ivar_get(name)
      instance_variable_get("@#{name}")
    end
    private :ivar_get

    # remove an instance variable by symbolic name
    def ivar_remove(name)
      if ivar_defined?(name)
        remove_instance_variable("@#{name}")
      end
    end
    private :ivar_remove

    # return true if attribute has default defined and not yet been
    # assigned to (i.e. still has default value)
    def default?(name)
      # FIXME: should this be in DoodleInfo or here?
      __doodle__.attributes[name.to_sym].optional? && !ivar_defined?(name)
    end

    # return true if attribute has been assigned to
    def assigned?(name)
      ivar_defined?(name)
    end

    # clear instance variable by removing it. This has the effect of
    # returning the attribute to its default value. Note that this can
    # leave the object in an invalid state. Caveat emptor (hence the !).
    def clear!(name)
      ivar_remove(name)
    end

    # provide a hook to re-order or massage arguments before being
    # processed by Doodle#initialize
    def preprocess_args(*a)
      a
    end

    # object can be initialized from a mixture of positional arguments,
    # hash of keyword value pairs and a block which is instance_eval'd
    def initialize(*args, &block)
      args = preprocess_args(*args)
      built_in = Doodle::BuiltIns::BUILTINS.select{ |x| self.kind_of?(x) }.first
      if built_in
        super
      end
      __doodle__.validation_on = true
      #p [:doodle_parent, Doodle.parent, caller[-1]]
      Doodle.context.push(self)
      __doodle__.defer_validation do
        __doodle__.update(*args, &block)
      end
      Doodle.context.pop
      #p [:doodle, __doodle__.__inspect__]
      #p [:doodle, __doodle__.attributes]
      #p [:doodle_parent, __doodle__.parent]
    end
  end
end
