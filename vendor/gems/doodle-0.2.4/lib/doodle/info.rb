class Doodle

  # place to stash bookkeeping info
  class DoodleInfo
    attr_accessor :this
    attr_accessor :local_attributes
    attr_accessor :local_validations
    attr_accessor :local_conversions
    attr_accessor :validation_on
    attr_accessor :arg_order
    attr_accessor :errors
    attr_accessor :parent

    # takes one param - the object being doodled
    def initialize(object)
      @this = object
      @local_attributes = Doodle::OrderedHash.new
      @local_validations = []
      @validation_on = true
      @local_conversions = {}
      @arg_order = []
      @errors = []
      #@parent = nil
      @parent = Doodle.parent
    end

    # hide from inspect
    m = instance_method(:inspect)
    define_method :__inspect__ do
      m.bind(self).call
    end

    # hide from inspect
    def inspect
      ''
    end

    # handle errors either by collecting in :errors or raising an exception
    def handle_error(name, *args)
      # don't include duplicates (FIXME: hacky - shouldn't have duplicates in the first place)
      if !errors.include?([name, *args])
        errors << [name, *args]
      end
      if Doodle.raise_exception_on_error
        raise(*args)
      end
    end

    # provide an alternative inheritance chain that works for singleton
    # classes as well as modules, classes and instances
    def parents
      anc = if @this.respond_to?(:ancestors)
              if @this.ancestors.include?(@this)
                @this.ancestors[1..-1]
              else
                # singletons have no doodle_parents (they're orphans)
                []
              end
            else
              @this.class.ancestors
            end
      anc.select{|x| x.kind_of?(Class)}
    end

    # send message to all doodle_parents and collect results
    def collect_inherited(message)
      result = []
      parents.each do |klass|
        if klass.respond_to?(:doodle) && klass.doodle.respond_to?(message)
          result.unshift(*klass.doodle.__send__(message))
        else
          break
        end
      end
      result
    end
    private :collect_inherited

    # collect results of calling method which returns a hash
    # - if tf == true, returns all inherited attributes
    # - if tf == false, returns only those attributes defined in the current object/class
    def handle_inherited_hash(tf, method)
      if tf
        collect_inherited(method).inject(Doodle::OrderedHash.new){ |hash, item|
          hash.merge(Doodle::OrderedHash[*item])
        }.merge(@this.doodle.__send__(method))
      else
        @this.doodle.__send__(method)
      end
    end
    private :handle_inherited_hash

    # returns array of Attributes
    # - if tf == true, returns all inherited attributes
    # - if tf == false, returns only those attributes defined in the current object/class
    def attributes(tf = true)
      results = handle_inherited_hash(tf, :local_attributes)
      # if an instance, include the singleton_class attributes
      #p [:attributes, @this, @this.singleton_class, @this.singleton_class.methods(false), results]
      if !@this.kind_of?(Class) && @this.singleton_class.doodle.respond_to?(:attributes)
        results = results.merge(@this.singleton_class.doodle.attributes)
      end
      results
    end

    # return class level attributes
    def class_attributes
      attrs = Doodle::OrderedHash.new
      if @this.kind_of?(Class)
        attrs = collect_inherited(:class_attributes).inject(Doodle::OrderedHash.new){ |hash, item|
          hash.merge(Doodle::OrderedHash[*item])
        }.merge(@this.singleton_class.doodle.respond_to?(:attributes) ? @this.singleton_class.doodle.attributes : { })
        attrs
      else
        @this.class.doodle.class_attributes
      end
    end

    # access list of validations
    #
    # note: validations are handled differently to attributes and
    # conversions because ~all~ validations apply (so are stored as an
    # array), whereas attributes and conversions are keyed by name and
    # kind respectively, so only the most recent applies
    #
    def validations(tf = true)
      if tf
        local_validations + collect_inherited(:local_validations)
      else
        local_validations
      end
    end

    # find an attribute
    def lookup_attribute(name)
      # (look at singleton attributes first)
      # fixme[this smells like a hack to me]
      if @this.class == Class
        class_attributes[name]
      else
        attributes[name]
      end
    end

    # returns hash of conversions
    # - if tf == true, returns all inherited conversions
    # - if tf == false, returns only those conversions defined in the current object/class
    def conversions(tf = true)
      handle_inherited_hash(tf, :local_conversions)
    end

    # return hash of key => value pairs of initial values (where defined)
    # - if tf == true, returns all inherited initial values
    # - if tf == false, returns only those initial values defined in current object/class
    def initial_values(tf = true)
      attributes(tf).select{|n, a| a.init_defined? }.inject({}) {|hash, (n, a)|
        #p [:initial_values, a.name]
        hash[n] = case a.init
                  when NilClass, TrueClass, FalseClass, Fixnum, Float, Bignum, Symbol
                    # uncloneable values
                    #p [:initial_values, :special, a.name, a.init]
                    a.init
                  when DeferredBlock
                    #p [:initial_values, self, DeferredBlock, a.name]
                    begin
                      @this.instance_eval(&a.init.block)
                    rescue Object => e
                      #p [:exception_in_deferred_block, e]
                      raise
                    end
                  else
                    if a.init.kind_of?(Class)
                      #p [:initial_values, :class]
                      a.init.new
                    else
                      #p [:initial_values, :clone, a.name]
                      begin
                        a.init.clone
                      rescue Exception => e
                        warn "tried to clone #{a.init.class} in :init option (#{e})"
                        #p [:initial_values, :exception, a.name, e]
                        a.init
                      end
                    end
                  end
        hash
      }
    end

    # turn off validation, execute block, then set validation to same
    # state as it was before +defer_validation+ was called - can be nested
    def defer_validation(&block)
      #p [:defer_validation, self.validation_on, @this]
      old_validation = self.validation_on
      self.validation_on = false
      v = nil
      begin
        v = @this.instance_eval(&block)
      ensure
        self.validation_on = old_validation
      end
      @this.validate!(false)
      v
    end

    # helper function to initialize from hash - this is safe to use
    # after initialization (validate! is called if this method is
    # called after initialization)
    def update(*args, &block)
      # p [:doodle_initialize_from_hash, :args, args, block]
      defer_validation do
        # this is ~very~ hacky
        if args.size == 1
          Doodle::Debug.d { [:update, "trying class conversion", args] }
          #p [self.class, :doodle_update, :args, 1, args]
          arg = *args
          if conversion = self.class.__doodle__.conversions[arg.class]
            Doodle::Debug.d { [:update, "found class conversion", args, conversion] }
            #p [:conversion, conversion, arg]
            args = [conversion.call(arg).to_hash]
            #p [:args, args]
            #return
          end
        end

        # hash initializer
        # separate into array of hashes of form [{:k1 => v1}, {:k2 => v2}] and positional args
        key_values, args = args.partition{ |x| x.kind_of?(Hash)}
        #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :key_values, key_values, :args, args] }
        #!p [self.class, :doodle_initialize_from_hash, :key_values, key_values, :args, args]

        # set up initial values with ~clones~ of specified values (so not shared between instances)
        #init_values = initial_values
        #!p [:init_values, init_values]

        # match up positional args with attribute names (from arg_order) using idiom to create hash from array of assocs
        #arg_keywords = init_values.merge(Hash[*(Utils.flatten_first_level(self.class.arg_order[0...args.size].zip(args)))])
        arg_keywords = Hash[*(Utils.flatten_first_level(self.class.arg_order[0...args.size].zip(args)))]
        #!p [self.class, :doodle_initialize_from_hash, :arg_keywords, arg_keywords]

        # merge all hash args into one
        key_values = key_values.inject(arg_keywords) { |hash, item|
          #!p [self.class, :doodle_initialize_from_hash, :merge, hash, item]
          hash.merge(item)
        }
        #!p [self.class, :doodle_initialize_from_hash, :key_values2, key_values]

        # convert keys to symbols (note not recursively - only first level == doodle keywords)
        Doodle::Utils.symbolize_keys!(key_values)
        #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :key_values2, key_values, :args2, args] }
        #p [self.class, :doodle_initialize_from_hash, :key_values3, key_values]
        # create attributes
        #p [:key_values, key_values]
        key_values.keys.each do |key|
          Doodle::Debug.d { [:update, "setting value", key, key_values[key]] }
          #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :setting, key, key_values[key]] }
          #p [self.class, :doodle_initialize_from_hash, :setting, key, key_values[key]]
          #p [:update, :setting, key, key_values[key], __doodle__.validation_on]
          if respond_to?(key)
            __send__(key, key_values[key])
          else
            # raise error if not defined
            __doodle__.handle_error key, Doodle::UnknownAttributeError, "unknown attribute '#{key}' => #{key_values[key].inspect} for #{self} #{doodle.attributes.map{ |k,v| k.inspect}.join(', ')}", Doodle::Utils.doodle_caller
          end
        end
        # do init_values after user supplied values so init blocks can
        # depend on user supplied values
        # - don't reset values which are supplied in args
        #p [:getting_init_values, instance_variables]
        begin
          __doodle__.initial_values.each do |key, value|
            #p [:test1, respond_to?(key) && !assigned?(key)]
            if !key_values.key?(key) && respond_to?(key)
              #p [:initial_values, key, value]
              #p [:ivar, ivar_get(key)]
              __send__(key, value)
              #p [:assigned?, assigned?(key)]
              #p [:ivar_2, ivar_get(key)]
            end
          end
        rescue Doodle::NoDefaultError => e
          # see bugs:core-28 - set init values from values set in block
          #p [:init, :doodle_no_default]
        end
        if block_given?
          #p [:update, block, __doodle__.validation_on]
          #p [:this, self]
          #p [:init, :instance_eval, caller]
          #p [:init, :instance_eval]
          instance_eval(&block)
        end
        # see bugs:core-28 - set init values from values set in block
        #p [:initial_values, __doodle__.initial_values]
        __doodle__.initial_values.each do |key, value|
          #p [:respond_to?, respond_to?(key), :assigned?, assigned?(key)]
          #p [:test2, respond_to?(key) && !assigned?(key)]
          #p [:ivar, ivar_get(key)]
          if respond_to?(key) && !assigned?(key)
            #p [:initial_values, key, value]
            __send__(key, value)
          end
        end
      end
      @this
    end

    # returns array of values (including defaults)
    # - if tf == true, returns all inherited values (default)
    # - if tf == false, returns only those values defined in current object
    def values(tf = true)
      attributes(tf).map{ |k, a| @this.send(k)}
    end

    # returns array of attribute names
    # - if tf == true, returns all inherited attribute names (default)
    # - if tf == false, returns only those attribute names defined in current object
    def keys(tf = true)
      attributes(tf).keys
    end

    # returns array of [key, value] pairs including default values
    # - if tf == true, returns all inherited [key, value] pairs (default)
    # - if tf == false, returns only those [key, value] pairs defined in current object
    def key_values(tf = true)
      keys(tf).zip(values(tf))
    end

    # returns array of [key, value] pairs excluding default values
    # - if tf == true, returns all inherited [key, value] pairs (default)
    # - if tf == false, returns only those [key, value] pairs defined in current object
    def key_values_without_defaults(tf = true)
      keys(tf).reject{|k| @this.default?(k) }.map{ |k, a| [k, @this.send(k)]}
    end

    # output doodle attributes as (nested) array of [key, value] pairs
    def to_a
      key_values.map{ |key, value|
        value = if value.kind_of?(Doodle)
                  value.doodle.to_a
                elsif value.kind_of?(Enumerable) && !value.kind_of?(String)
                  value.map{ |y| y.kind_of?(Doodle) ? y.doodle.to_a : y.to_a }
                else
                  value
                end
        [key, value]
      }
    end
  end
end
