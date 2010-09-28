class Doodle

  def self.TypedArray(*klasses)
    typed_class = Class.new(NormalizedArray) do
      define_method :normalize_value do |v|
        if !klasses.any?{ |klass| v.kind_of?(klass) }
          raise TypeError, "#{self.class}: #{v.class}(#{v.inspect}) is not a kind of #{klasses.map{ |c| c.to_s }.join(', ')}", [caller[-1]]
        end
        v
      end
    end
    #p [:creating_class, typed_class]
    typed_class
  end

  # base class for attribute collector classes
  class AttributeCollector < DoodleAttribute
    # FIXME: collector
    has :collector_spec, :init => { }

    def create_collection
      if self.init.kind_of?(Class)
        #p [:create_collection, :class]
        collection = self.init.new
      else
        #p [:create_collection, :clone]
        collection = self.init.clone
      end
      #p [:create_collection, collection]
      collection
    end
    private :create_collection

    def resolve_collector_class
      # FIXME: collector - perhaps don't allow non-class collectors - should be resolved by this point
      # perhaps do this in init?
      collector_spec.each do |k, v|
        if !v.kind_of?(Class)
          collector_spec[k] = Doodle::Utils.const_resolve(v)
        end
      end
    end

    def resolve_value(value)
      klasses = collector_spec.values
      # FIXME: collector - find applicable collector class
      if klasses.any? { |x| value.kind_of?(x) }
        # no change required
        #p [:resolve_value, :value, value]
        value
      elsif collector_class = klasses.select { |klass| klass.respond_to?(:__doodle__) && klass.__doodle__.conversions.key?(value.class) }.first
        # if the collector_class has a specific conversion for this value class
        #p [:resolve_value, :collector_class_from, value]
        collector_class.from(value)
      else
        collector_class = klasses.first
        # try to instantiate collector_class using raw value
        #p [:resolve_value, :collector_class_new, value]
        collector_class.new(value)
      end
    end

    def initialize(*args, &block)
      #p [self.class, :initialize]
      super
      define_collector
      from Hash do |hash|
        # FIXME: collector - my bogon detector just went off the scale - I forget why I have to do this here... :/
        # oh yes - because I allow forward references using symbols or strings
        resolve_collector_class
        collection = create_collection
        hash.inject(collection) do |h, (key, value)|
          h[key] = resolve_value(value)
          h
        end
      end
      from Enumerable do |enum|
        #p [:enum, Enumerable]
        # FIXME: collector
        resolve_collector_class
        # this is not very elegant but String is a classified as an
        # Enumerable in 1.8.x (but behaves differently)
        if enum.kind_of?(String) && self.init.kind_of?(String)
          post_process( resolve_value(enum) )
        else
          post_process( enum.map{ |value| resolve_value(value) } )
        end
      end
    end

    def post_process(results)
      #p [:post_process, results]
      collection = create_collection
      collection.replace(results)
    end
  end

  class AppendableAttribute < AttributeCollector
    #    has :init, :init => DoodleArray.new
    has :init, :init => []
  end

  # define collector methods for hash-like attribute collectors
  class KeyedAttribute < AttributeCollector
    #    has :init, :init => DoodleHash.new
    has :init, :init => { }
    #has :init, :init => OrderedHash.new
    has :key

    def post_process(results)
      collection = create_collection
      results.inject(collection) do |h, result|
        h[result.send(key)] = result
        h
      end
    end
  end
end

if RUBY_VERSION >= '1.8.7'
  # load ruby 1.8.7+ version specific methods
  require 'doodle/collector-1.9'
else
  # version for ruby 1.8.6
  class Doodle

    # define collector methods for array-like attribute collectors
    class AppendableAttribute < AttributeCollector

      # define a collector for appendable collections
      # - collection should provide a :<< method
      def define_collector
        collector_spec.each do |collector_name, collector_class|
          if collector_class.nil?
            doodle_owner.sc_eval(<<-EOT, __FILE__, __LINE__)
              def #{collector_name}(*args, &block)
                Doodle::Debug.d { [:#{collector_name}_1, args, block] }
                args.unshift(block) if block_given?
                send(:#{name}).<<(*args)
              end
            EOT
          else
            doodle_owner.sc_eval(<<-EOT, __FILE__, __LINE__)
              def #{collector_name}(*args, &block)
                Doodle::Debug.d { [:#{collector_name}_2, args, block] }
                collection = send(:#{name})
                if args.size > 0 and args.all?{|x| x.kind_of?(#{collector_class})}
                  collection.<<(*args)
                else
                  collection << #{collector_class}.new(*args, &block)
                end
              end
            EOT
          end
        end
      end
    end

    class KeyedAttribute

      # define a collector for keyed collections
      # - collection should provide :[], :clone and :replace methods
      def define_collector
        collector_spec.each do |collector_name, collector_class|
          # need to use string eval because passing block
          if collector_class.nil?
            doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                     collection = #{name}
                     args.each do |arg|
                       #{name}[arg.send(:#{key})] = arg
                     end
                   end", __FILE__, __LINE__)
          else
            doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                            collection = #{name}
                            if args.size > 0 and args.all?{|x| x.kind_of?(#{collector_class})}
                              args.each do |arg|
                                #{name}[arg.send(:#{key})] = arg
                              end
                            else
                              obj = #{collector_class}.new(*args, &block)
                              #{name}[obj.send(:#{key})] = obj
                            end
                       end", __FILE__, __LINE__)
          end
        end
      end
    end
  end
end
