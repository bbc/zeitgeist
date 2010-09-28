class Doodle
  # = inherit
  # the intent of inherit is to provide a way to create directives
  # that affect all members of a class 'family' without having to
  # modify Module, Class or Object - in some ways, it's similar to Ara
  # Howard's mixable[http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/197296]
  # though not as tidy :S
  #
  # this works down to third level <tt>class << self</tt> - in practice, this is
  # perfectly good - it would be great to have a completely general
  # solution but I doubt whether the payoff is worth the effort

  module Inherited
    def self.included(other)
      other.extend(Inherited)
      other.send(:include, Factory)
    end

    # fake module inheritance chain
    def inherit(other, &block)
      # include in instance method chain
      include other
      include Inherited

      sc = class << self; self; end
      sc.module_eval {
        # class method chain
        include other
        # singleton method chain
        extend other
        # ensure that subclasses also inherit this module
        define_method :inherited do |klass|
          #p [:inherit, :inherited, klass]
          klass.__send__(:inherit, other)       # n.b. closure
        end
      }
    end
  end

end
