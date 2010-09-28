class Doodle

  # what it says on the tin :) various hacks to hide @__doodle__ variable
  module SmokeAndMirrors

    # redefine instance_variables to ignore our private @__doodle__ variable
    # (hack to fool yaml and anything else that queries instance_variables)
    meth = Object.instance_method(:instance_variables)
    define_method :instance_variables do
      meth.bind(self).call.reject{ |x| x.to_s =~ /@__doodle__/}
    end

    # hide @__doodle__ from inspect
    def inspect
      super.gsub(/\s*@__doodle__=,/,'').gsub(/,?\s*@__doodle__=/,'')
    end

    # fix for pp
    def pretty_print(q)
      q.pp_object(self)
    end
  end
end
