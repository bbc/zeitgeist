class Doodle
  # A Validation represents a validation rule applied to the instance
  # after initialization. Generated using the Doodle::BaseMethods#must directive.
  class Validation
    attr_accessor :message
    attr_accessor :block
    # create a new validation rule. This is typically a result of
    # calling +must+ so the text should work following the word
    # "must", e.g. "must not be nil", "must be >= 10", etc.
    def initialize(message = 'not be nil', &block)
      @message = message
      @block = block_given? ? block : proc { |x| !self.nil? }
    end
  end

  module ValidationHelper
    # add a validation
    def must(constraint = 'be valid', &block)
      __doodle__.local_validations << Validation.new(constraint, &block)
    end

    # add a validation that attribute must be of class <= kind
    def kind(*args, &block)
      if args.size > 0
        @kind = [args].flatten
        # todo[figure out how to handle kind being specified twice?]
        if @kind.size > 2
          kind_text = "be a kind of #{ @kind[0..-2].map{ |x| x.to_s }.join(', ') } or #{@kind[-1].to_s}" # =>
        else
          kind_text = "be a kind of #{@kind.to_s}"
        end
        __doodle__.local_validations << (Validation.new(kind_text) { |x| @kind.any? { |klass| x.kind_of?(klass) } })
      else
        @kind ||= []
      end
    end

    # validate that individual attribute args meet rules defined with +must+
    # fixme: move
    def validate(owner, *args)
      Doodle::Debug.d { [:validate, 1, owner, args] }
      ##DBG: Doodle::Debug.d { [:validate, self, :owner, owner, :args, args ] }
      #p [:validate, 1, args]
      begin
        Doodle::Debug.d { [:validate, 2] }
        value = convert(owner, *args)
      rescue Exception => e
        owner.__doodle__.handle_error name, ConversionError, "#{owner.kind_of?(Class) ? owner : owner.class}.#{ name } - #{e.message}", Doodle::Utils.doodle_caller(e)
      end
      #
      # Note to self: these validations are not affected by
      # doodle.validation_on because they are for ~individual
      # attributes~ - validation_on is for the ~object as a whole~ -
      # so don't futz with this again :)
      #
      # p [:validate, 2, args, :becomes, value]
      __doodle__.validations.each do |v|
        ##DBG: Doodle::Debug.d { [:validate, self, v, args, value] }
        if !v.block[value]
          owner.__doodle__.handle_error name, ValidationError, "#{owner.kind_of?(Class) ? owner : owner.class}.#{ name } must #{ v.message } - got #{ value.class }(#{ value.inspect })", Doodle::Utils.doodle_caller
        end
      end
      #p [:validate, 3, value]
      value
    end

    # validate this object by applying all validations in sequence
    #
    # - if all == true, validate all attributes, e.g. when loaded from
    #   YAML, else validate at object level only
    #
    def validate!(all = true)
      ##DBG: Doodle::Debug.d { [:validate!, all, caller] }
      if all
        __doodle__.errors.clear
      end

      # first check that individual attributes are valid

      if __doodle__.validation_on
        if self.class == Class
          attribs = __doodle__.class_attributes
          ##DBG: Doodle::Debug.d { [:validate!, "using class_attributes", class_attributes] }
        else
          attribs = __doodle__.attributes
          ##DBG: Doodle::Debug.d { [:validate!, "using instance_attributes", doodle.attributes] }
        end
        attribs.each do |name, att|
          if ivar_defined?(name)
            # if all == true, reset values so conversions and
            # validations are applied to raw instance variables
            # e.g. when loaded from YAML
            if all && !att.readonly
              ##DBG: Doodle::Debug.d { [:validate!, :sending, att.name, instance_variable_get(ivar_name) ] }
              __send__("#{name}=", ivar_get(name))
            end
          elsif att.optional?   # treat default/init as special case
            ##DBG: Doodle::Debug.d { [:validate!, :optional, name ]}
            next
          elsif self.class != Class
            __doodle__.handle_error name, Doodle::ValidationError, "#{self.kind_of?(Class) ? self : self.class } missing required attribute '#{name}'", Doodle::Utils.doodle_caller
          end
        end

        # now apply whole object level validations

        ##DBG: Doodle::Debug.d { [:validate!, "validations", doodle_validations ]}
        __doodle__.validations.each do |v|
          ##DBG: Doodle::Debug.d { [:validate!, self, v ] }
          begin
            if !instance_eval(&v.block)
              __doodle__.handle_error self, ValidationError, "#{ self.class } must #{ v.message }", Doodle::Utils.doodle_caller
            end
          rescue Exception => e
            __doodle__.handle_error self, ValidationError, e.to_s, Doodle::Utils.doodle_caller(e)
          end
        end
      end
      # if OK, then return self
      self
    end

  end
end
