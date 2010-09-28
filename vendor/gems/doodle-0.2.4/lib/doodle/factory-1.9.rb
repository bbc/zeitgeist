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
            # this one is proving tricky to convert
            eval("def #{ name }(*args, &block); ::#{name}.new(*args, &block); end;", ::TOPLEVEL_BINDING, __FILE__, __LINE__)
            #parent_class = eval("class << self; self; end", ::TOPLEVEL_BINDING, __FILE__, __LINE__)
            #parent_class.send(:define_method, name) { |*args, &block| klass.new(*args, &block) }
          end
        else
          #p [:factory, :other_level_class]
          parent_class = Object
          if !anon_class
            parent_class = names.inject(parent_class) {|c, n| c.const_get(n)}
            #p [:factory, :parent_class, parent_class]
            if name =~ Factory::RX_IDENTIFIER && !parent_class.respond_to?(name)
              klass = parent_class.const_get(name)
              parent_class.module_eval { (class << self; self; end).send(:define_method, name) { |*args, &block| klass.new(*args, &block) } }
            end
          else
            # NOTE: ruby 1.9.1 specific
            parent_class_name = names.join('::')
            #p [:factory, :parent_class_name, parent_class_name]
            #p [:parent_class_name, parent_class_name]
            # FIXME: this is truly horrible...
            hex_object_id = parent_class_name.match(/:(0x[a-zA-Z0-9]+)/)[1]
            oid = hex_object_id.to_i(16) >> 1
            #             p [:object_id, oid, hex_object_id, hex_object_id.to_i(16) >> 1]
            parent_class = ObjectSpace._id2ref(oid)

            #p [:parent_object_id, parent_class.object_id, names, parent_class, parent_class_name, parent_class.name]
            #             p [:names, :oid, "%x" % (oid << 1), :konst, konst, :pc, parent_class, :names, names, :self, self]
            if name =~ Factory::RX_IDENTIFIER && !parent_class.respond_to?(name) && parent_class.const_defined?(name)
              #p [:context, context]
              klass = parent_class.const_get(name)
              parent_class.module_eval { define_method(name) { |*args, &block| klass.new(*args, &block) }}
            end
          end
          # TODO: check how many times this is being called
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
