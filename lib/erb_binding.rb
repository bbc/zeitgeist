require 'erb'
module ErbBinding
  extend self

  ## create_binding_object
  # create a throw-away object to hold parameters as methods
  def create_binding_object(params)
    o = Object.new
    o.instance_eval do
      klass = class << self; self; end
      # fake
      params.each do |key, value|
        klass.send(:define_method, key) do value end
      end
    end
    def o.context
      self.instance_eval { binding }
    end
    o
  end
  ## erb
  def erb(template, params = { })
    o = create_binding_object(params)
    ERB.new(template, nil, '%<>').result(o.context)
  end
end
