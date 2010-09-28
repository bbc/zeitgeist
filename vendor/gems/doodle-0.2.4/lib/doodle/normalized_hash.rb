# NormalizedHash - ensure hash keys and/or values are normalized to
# particular type
#
# To use, derive a subclass from NormalizeKeyHash and provide you own
# normalize_key(key) method
#
# See StringKeyHash and SymbolKeyHash for examples
#
# Sean O'Halpin, 2004..2009

module ModNormalizedHash
  module InstanceMethods
    def initialize(arg = {}, &block)
      if block_given?
        original_block = block
        # this is unfortunate
        block = proc { |h, k|
          #p [:block, h, k]
          res = normalize_value(original_block[h, normalize_key(k)])
          #p [:block_self, self, res]
          each do |k2, v2|
            #p [:init_block, k, v]
            self[k2] = normalize_value(v2)
          end
          #p [:block_res, self, res]
          res
        }
      end
      if arg.is_a?(Hash)
        super(&block)
        update(arg)
      else
        super(arg, &block)
      end
    end

    def default(k)
      super(normalize_key(k))
    end

    def default=(value)
      super(normalize_value(value))
    end

    def store(k,v)
      super(normalize_key(k), normalize_value(v))
    end

    def fetch(k)
      super(normalize_key(k))
    end

    # Note that invert returns a new +Hash+. This is by design. If you want the new hash to have the same properties as its source,
    # use something like:
    #
    #   h = StringKeyHash.new(h.invert)
    #
    #     def invert
    #       super
    #     end

    def delete(k)
      super(normalize_key(k))
    end

    def [](k)
      super(normalize_key(k))
    end

    def []=(k,v)
      super(normalize_key(k), normalize_value(v))
    end

    def key?(k)
      super(normalize_key(k))
    end
    alias :has_key? :key?
    alias :member? :has_key?
    alias :include? :has_key?

    def has_value?(v)
      super(normalize_value(v))
    end
    alias :value? :has_value?

    def update(other, &block)
      if block_given?
        # {|key, oldval, newval| block}
        super(other) { |key, oldval, newval|
          normalize_value(block.call(key, oldval, newval))
        }
      else
        other.each do |k,v|
          store(k,v)
        end
      end
    end
    alias :merge! :update

    def merge(other)
      self.dup.update(other)
    end

    def values_at(*keys)
      super(*keys.map{ |k| normalize_key(k)})
    end
    alias :indices :values_at # deprecated
    alias :indexes :values_at # deprecated

    def replace(other)
      self.clear
      update(other)
    end

    def index(value)
      super(normalize_value(v))
    end

    # implemented in super
    #   def clear
    #     super
    #   end

    #   def default_proc
    #     super
    #   end

    #   def delete_if(&block)
    #     super
    #   end

    #   def each(&block)
    #     super
    #   end

    #   def each_key(&block)
    #     super
    #   end

    #   def each_pair(&block)
    #     super
    #   end

    #   def each_value(&block)
    #     super
    #   end

    #   def empty?
    #     super
    #   end

    #   def invert
    #     super
    #   end

    #   def keys
    #     super
    #   end

    #   def length
    #     super
    #   end
    #   alias :size :length

    #   def rehash
    #     super
    #   end

    #   def reject!(&block)
    #     super
    #   end

    #   def shift
    #     super
    #   end

    #   def to_hash
    #     super
    #   end

    #   def values
    #     super
    #   end
  end

  module ClassMethods
    def [](*args)
      new(Hash[*args])
    end
  end

  # in normal usage, these are the only methods you should need to override
  module OverrideMethods
    # override this method to normalize key, e.g. to normalize keys to
    # strings:
    #
    #   def normalize_key(k)
    #     k.to_s
    #   end
    def normalize_key(k)
      k
    end

    # override this method to normalize value, e.g. to normalize
    # values to strings:
    #
    #   def normalize_value(v)
    #     v.to_s
    #   end
    def normalize_value(v)
      v
    end
  end

end

# Note that some methods return a new +Hash+ not an object of your
# subclass. This is by design (i.e. it's how ruby works). If you want
# the new hash to have the same properties as its source, use
# something like:
#
#   h = StringKeyHash.new(h.invert)
#
# The methods are:
#
#   invert => Hash
#   select, reject => Hash in 1.9
class NormalizedHash < Hash
  include ModNormalizedHash::InstanceMethods
  include ModNormalizedHash::OverrideMethods
  extend ModNormalizedHash::ClassMethods
end

class SymbolKeyHash < NormalizedHash
  def normalize_key(k)
    k.to_s.to_sym
  end
end

class StringKeyHash < NormalizedHash
  def normalize_key(k)
    #p [:normalizing, k]
    k.to_s
  end
end

class StringHash < StringKeyHash
  def normalize_value(v)
    v.to_s
  end
end

module ModNormalizedHash
  module ClassMethods
    def TypedHash(*klasses, &block)
      typed_class = Class.new(NormalizedHash) do
        # note: cannot take a block
        if block_given?
          define_method :normalize_value, &block
        else
          define_method :normalize_value do |v|
            if !klasses.any?{ |klass| v.kind_of?(klass) }
              raise TypeError, "#{self.class}: #{v.class}(#{v.inspect}) is not a kind of #{klasses.map{ |c| c.to_s }.join(', ')}", [caller[-1]]
            end
            v
          end
        end
      end
      typed_class
    end
  end
end

