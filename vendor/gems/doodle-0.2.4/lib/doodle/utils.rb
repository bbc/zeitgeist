# Set of utility functions to avoid monkeypatching base classes
class Doodle
  # Set of utility functions to avoid monkeypatching base classes
  module Utils
    module ClassMethods

      # unnest arrays by one level of nesting, e.g. [1, [[2], 3]] =>
      # [1, [2], 3].
      def flatten_first_level(enum)
        enum.inject([]) {|arr, i|
          if i.kind_of?(Array)
            arr.push(*i)
          else
            arr.push(i)
          end
        }
      end

      # convert an array of key,value pairs into hash
      def to_hash(ary)
        Hash[*flatten_first_level(ary)]
      end

      # convert an array of key,value pairs into hash
      def to_ordered_hash(ary)
        OrderedHash[*flatten_first_level(ary)]
      end

      # convert a CamelCasedWord to a snake_cased_word
      # based on version in facets/string/case.rb, line 80
      def snake_case(camel_cased_word)
        # if all caps, just downcase it
        if camel_cased_word =~ /^[A-Z]+$/
          camel_cased_word.downcase
        else
          camel_cased_word.to_s.gsub(/([A-Z]+)([A-Z])/,'\1_\2').gsub(/([a-z])([A-Z])/,'\1_\2').downcase
        end
      end
      alias :snakecase :snake_case

      # convert a snake_cased_word to CamelCased
      # pinched from #camelize in activesupport
      def camel_case(lower_case_and_underscored_word, first_letter_in_uppercase = true)
        if first_letter_in_uppercase
          lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
        else
          lower_case_and_underscored_word[0..0] + camel_case(lower_case_and_underscored_word)[1..-1]
        end
      end
      alias :camelcase :camel_case
      alias :camelize :camel_case

      # resolve a constant of the form Some::Class::Or::Module -
      # doesn't work with constants defined in anonymous
      # classes/modules
#       def const_resolve(constant)
#         constant.to_s.split(/::/).reject{|x| x.empty?}.inject(Object) { |prev, this| prev.const_get(this) }
#       end
      # Rick de Natale's version: see ruby-talk:332670
      def const_resolve(const_name)
        const_name.to_s.
          sub(/^::/,'').
          split("::").
          inject(Object) { |scope, name| scope.const_defined?(name) ?
          scope.const_get(name) : scope.const_missing(name) }
      end

      # deep copy of object (unlike shallow copy dup or clone)
      def deep_copy(obj)
        ::Marshal.load(::Marshal.dump(obj))
      end

      # normalize hash keys using method (e.g. +:to_sym+, +:to_s+)
      #
      # [+hash+] target hash to update
      # [+recursive+] recurse into child hashes if +true+ (default is not to recurse)
      # [+method+] method to apply to key (default is +:to_sym+)
      def normalize_keys!(hash, recursive = false, method = :to_sym)
        if hash.kind_of?(Hash)
          hash.keys.each do |key|
            normalized_key = key.respond_to?(method) ? key.send(method) : key
            v = hash.delete(key)
            if recursive
              if v.kind_of?(Hash)
                v = normalize_keys!(v, recursive, method)
              elsif v.kind_of?(Array)
                v = v.map{ |x| normalize_keys!(x, recursive, method) }
              end
            end
            hash[normalized_key] = v
          end
        end
        hash
      end

      # normalize hash keys using method (e.g. :to_sym, :to_s)
      # - returns copy of hash
      # - optionally recurse into child hashes
      # see #normalize_keys! for details
      def normalize_keys(hash, recursive = false, method = :to_sym)
        if recursive
          h = deep_copy(hash)
        else
          h = hash.dup
        end
        normalize_keys!(h, recursive, method)
      end

      # convert keys to symbols
      # - updates target hash in place
      # - optionally recurse into child hashes
      def symbolize_keys!(hash, recursive = false)
        normalize_keys!(hash, recursive, :to_sym)
      end

      # convert keys to symbols
      # - returns copy of hash
      # - optionally recurse into child hashes
      def symbolize_keys(hash, recursive = false)
        normalize_keys(hash, recursive, :to_sym)
      end

      # convert keys to strings
      # - updates target hash in place
      # - optionally recurse into child hashes
      def stringify_keys!(hash, recursive = false)
        normalize_keys!(hash, recursive, :to_s)
      end

      # convert keys to strings
      # - returns copy of hash
      # - optionally recurse into child hashes
      def stringify_keys(hash, recursive = false)
        normalize_keys(hash, recursive, :to_s)
      end

      # simple (!) pluralization - if you want fancier, override this method
      def pluralize(string)
        s = string.to_s
        if s =~ /[sx]$/
          s + 'es'
        elsif s =~ /[y]$/
          s[0..-2] + 'ies'
        else
          s + 's'
        end
      end

      # caller
      def doodle_caller(e = nil)
        # TODO: tidy this up - use backtrace as arg?
        if e.nil?
          res = caller
        else
          res = e.backtrace
        end
        if $DEBUG
          res
        else
          # pp [:res, res]
          # result = []
          # res.reverse_each do |r|
          #   if r =~ %r{/doodle/lib}
          #     break
          #   end
          #   result << r
          # end
          # result.reverse
          res.reject{ |x| x =~ %r{/doodle/lib}}
        end
      end

      # execute block - catch any exceptions and return as value
      def try(&block)
        begin
          block.call
        rescue Exception => e
          e
        end
      end

      # normalize a name to contain only those characters which are
      # valid for a Ruby constant
      def normalize_const(const)
        const.to_s.gsub(/[^A-Za-z_0-9]/, '')
      end

      # lookup a constant along the module nesting path
      def const_lookup(const, context = self)
        #p [:const_lookup, const, context]
        const = Utils.normalize_const(const)
        result = nil
        if !context.kind_of?(Module)
          context = context.class
        end
        klasses = context.to_s.split(/::/)
        #p klasses

        path = []
        0.upto(klasses.size - 1) do |i|
          path << Doodle::Utils.const_resolve(klasses[0..i].join('::'))
        end
        path = (path.reverse + context.ancestors).flatten
        #p [:const, context, path]
        path.each do |ctx|
          #p [:checking, ctx]
          if ctx.const_defined?(const)
            result = ctx.const_get(const)
            break
          end
        end
        if result.nil?
          raise NameError, "Uninitialized constant #{const} in context #{context}"
        else
          result
        end
      end
    end
    extend ClassMethods
    include ClassMethods
  end
end
