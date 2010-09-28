class Doodle
  # error handling
  @@raise_exception_on_error = true
  def self.raise_exception_on_error
    @@raise_exception_on_error
  end
  def self.raise_exception_on_error=(tf)
    @@raise_exception_on_error = tf
  end

  # base exception class
  class DoodleException < StandardError
  end
  # internal error raised when a default was expected but not found
  class NoDefaultError < DoodleException
  end
  # raised when a validation rule returns false
  class ValidationError < DoodleException
  end
  # raised when an unknown parameter is passed to initialize
  class UnknownAttributeError < DoodleException
  end
  # raised when a conversion fails
  class ConversionError < DoodleException
  end
  # raised when arg_order called with incorrect arguments
  class InvalidOrderError < DoodleException
  end
  # raised when try to set a readonly attribute after initialization
  class ReadOnlyError < DoodleException
  end
end
