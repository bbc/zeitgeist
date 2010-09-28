if RUBY_VERSION >= '1.8.7'
  require 'doodle/factory-1.9'
else
  class Doodle
    # A factory function is a function that has the same name as
    # a class which acts just like class.new. For example:
    #   Cat(:name => 'Ren')
    # is the same as:
    #   Cat.new(:name => 'Ren')
    # also works in subclasses
    #   class Animal < Doodle
    #   end
    #   class Dog < Animal
    #   end
    #   stimpy = Dog(:name => 'Stimpy')
    # etc.
    #
    # maybe should just call this a Constructor function
    #
    module Factory
      RX_IDENTIFIER = /^[A-Za-z_][A-Za-z_0-9]+\??$/
      module ClassMethods
        # create a factory function in appropriate module for the specified class
        def factory(konst)
          #p [:factory, :ancestors, konst, konst.ancestors]
          #p [:factory, :lookup, Module.nesting]
          name = konst.to_s
          return if name =~ /^Doodle$/
          #p [:factory, :name, name]
          anon_class = false
          if name =~ /#<Class:0x[a-fA-F0-9]+>::/
              #p [:factory_anon_class, name]
              anon_class = true
          end
          names = name.split(/::/)
          name = names.pop
          # TODO: the code below is almost the same - refactor
          #p [:factory, :names, names, name]
          if names.empty? && !anon_class
            #p [:factory, :top_level_class]
            # top level class - should be available to all
            parent_class = Object
            method_defined = method_defined?(name)
            if name =~ Factory::RX_IDENTIFIER && !method_defined && !parent_class.respond_to?(name) && !eval("respond_to?(:#{name})", TOPLEVEL_BINDING)
              eval("def #{ name }(*args, &block); ::#{name}.new(*args, &block); end;", ::TOPLEVEL_BINDING, __FILE__, __LINE__)
            end
          else
            #p [:factory, :other_level_class]
            parent_class = Object
            parent_class = names.inject(parent_class) {|c, n| c.const_get(n)}
            #p [:factory, :parent_class, parent_class]
            if name =~ Factory::RX_IDENTIFIER && !parent_class.respond_to?(name)
              # FIXME: find out why define_method version not working
              parent_class.module_eval("def self.#{name}(*args, &block); #{name}.new(*args, &block); end", __FILE__, __LINE__)
            end
          end
        end

        # inherit the factory function capability
        def included(other)
          #p [:included, other]
          super
          # make +factory+ method available
          factory other
        end
      end
      extend ClassMethods
    end
  end
end
