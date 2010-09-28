if RUBY_VERSION < '1.9.0'
  require 'molic_orderedhash'  # TODO: replace this with own (required functions only) version
else
  # 1.9+ hashes are ordered by default
  class Doodle
    OrderedHash = ::Hash
  end
end
