## User
class User
  def self.reload; Kernel.load __FILE__; end
  include DataMapper::Resource
  include DBObject

  has n, :tweets, :child_key => [:user_id]

  property :user_id, Integer, :min => 0, :max => BIGINT, :key => true
  property :name, String, :length => 255
  property :screen_name, String, :length => 255
end

