## requires
require 'dm-types'
require 'dm-validations'
require 'escape_xml'

## models
### Feedback
class Feedback
  def self.reload; Kernel.load __FILE__; end

  include DataMapper::Resource
  include DBObject

  property :id, Serial
  property :name, String, :length => 255, :required => false
  property :email, String, :length => 255, :format => :email_address, :required => false, :messages => {
    :format => "That doesn't look like an email address to me..."
  }
  property :comments, Text, :required => true, :messages => {
    :presence => "We'd like your feedback",
  }
  property :created_at, Time
  property :processed, Boolean, :default => false

  before :save, :update_time

  def update_time
    self.created_at = Time.now
  end

end

