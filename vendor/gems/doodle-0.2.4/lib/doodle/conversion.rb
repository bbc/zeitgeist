class Doodle
  module ConversionHelper
    # if block passed, define a conversion from class
    # if no args, apply conversion to arguments
    def from(*args, &block)
      Doodle::Debug.d { [self, args, block]}
      #p [:from, self, args]
      if block_given?
        # set the rule for each arg given
        args.each do |arg|
          __doodle__.local_conversions[arg] = block
        end
      else
        convert(self, *args)
      end
    end

    class Proxy < Proc
      attr_accessor :owner
      def initialize(owner, &block)
        @owner = owner
        super(&block)
      end
    end

    def apply_conversion(owner, converter, value)
      converter[value]
    end

    # convert a value according to conversion rules
    # FIXME: move & review scope (e.g. instance eval in owning object?)
    def convert(owner, *args)
      Doodle::Debug.d { [:convert, 1, owner, args] }
      begin
        args = args.map do |value|
          Doodle::Debug.d { [:convert, 2, value, value.class, __doodle__.conversions.keys] }
          if (converter = __doodle__.conversions[value.class])
            Doodle::Debug.d { [:convert, 3, converter] }
            value = apply_conversion(owner, converter, value)
            Doodle::Debug.d { [:convert, 4, value] }
          else
            Doodle::Debug.d { [:convert, 5, value] }
            # try to find nearest ancestor
            this_ancestors = value.class.ancestors
            Doodle::Debug.d { [:convert, 6, this_ancestors] }
            matches = this_ancestors & __doodle__.conversions.keys
            Doodle::Debug.d { [:convert, 7, matches] }
            indexed_matches = matches.map{ |x| this_ancestors.index(x)}
            Doodle::Debug.d { [:convert, 8, indexed_matches] }
            if indexed_matches.size > 0
              Doodle::Debug.d { [:convert, 9] }
              converter_class = this_ancestors[indexed_matches.min]
              Doodle::Debug.d { [:convert, 10, converter_class] }
              if converter = __doodle__.conversions[converter_class]
                Doodle::Debug.d { [:convert, 11, converter] }
                value = apply_conversion(owner, converter, value)
                Doodle::Debug.d { [:convert, 12, value] }
              end
            else
              Doodle::Debug.d { [:convert, 13, :kind, kind, name, value] }
              mappable_kinds = kind.select{ |x| x <= Doodle::Core }
              Doodle::Debug.d { [:convert, 13.1, :kind, kind, mappable_kinds] }
              if mappable_kinds.size > 0
                mappable_kinds.each do |mappable_kind|
                  Doodle::Debug.d { [:convert, 14, :kind_is_a_doodle, value.class, mappable_kind, mappable_kind.doodle.conversions, args] }
                  if converter = mappable_kind.doodle.conversions[value.class]
                    Doodle::Debug.d { [:convert, 15, value, mappable_kind, args] }
                    value = apply_conversion(owner, converter, value)
                    break
                  else
                    Doodle::Debug.d { [:convert, 16, :no_conversion_for, value.class] }
                  end
                end
              else
                Doodle::Debug.d { [:convert, 17, :kind_has_no_conversions] }
              end
            end
          end
          Doodle::Debug.d { [:convert, 18, value] }
          value
        end
      rescue Exception => e
        Doodle::Debug.d { [:convert, 19, :exception] }
        owner.__doodle__.handle_error name, ConversionError, "#{e.message}", Doodle::Utils.doodle_caller(e)
      end
      if args.size > 1
        Doodle::Debug.d { [:convert, 20] }
        args
      else
        Doodle::Debug.d { [:convert, 21] }
        args.first
      end
    end
  end
end
