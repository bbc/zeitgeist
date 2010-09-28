## DBObject
module DBObject
  BIGINT = 2**64-1
  def find_or_create(*params)
    self.first(*params) || self.new(*params)
  end
end

