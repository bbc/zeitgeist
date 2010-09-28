## Tweet
require 'json'
require 'dm-types'
require 'similarity'

class Tweet
  def self.reload; Kernel.load __FILE__; end

  include DataMapper::Resource
  include DBObject

  has n, :links, :through => Resource
  belongs_to :user, :child_key => [:user_id]

  property :twid, Integer, :min => 0, :max => BIGINT, :key => true
  # property :user_id, Integer, :min => 0, :max => BIGINT
  property :text, String, :length => 1024
  property :created_at, Time, :index => true
  # this didn't create the index - I did this directly on the database
  # CREATE index idx_tweets_created_at ON tweets(created_at);
  # CREATE index idx_tweet_twid ON link_tweets(tweet_twid);

  # original tweet
  property :tweet, Json

  belongs_to :parent_tweet, :model => Tweet, :required => false
  has n, :retweets, :model => Tweet, :child_key => [:parent_tweet_twid]

  before :save do
    # if retweet specified use it
    if self.parent_tweet.nil?
      if rs = tweet["retweeted_status"]
        if parent = Tweet.from_hash(rs)
          self.parent_tweet = parent
        end
      end
      # if still nil, use heuristic method
      self.parent_tweet ||= calc_retweet_of
    end
  end

  class << self
    # scopes
    def original
      all(:parent_tweet => nil)
    end

    def retweets
      all(:parent_tweet.not => nil)
    end
  end

  ## Tweet.from_hash(data)
  # create a tweet, user and links from hash of twitter data
  def self.from_hash(data)
    tweet = self.first(:twid => data["id"]) || self.new
    tweet.twid = data["id"]
    # tweet.user_id = data["user"]["id"]
    tweet.text = data["text"]
    tweet.created_at = Time.parse(data["created_at"])
    tweet.tweet = data

    existing_links = tweet.links.map{ |link| link.url }.compact
    if data["resolved_links"]
      new_links = (data["resolved_links"].uniq - existing_links).compact.map{ |url|
        url = url[0..254]
        if link = Link.first(:url => url)
          link
        else
          link = Link.new(:url => url)
          #link.update_metadata # leave to offline job
          link
        end
      }
      if new_links.size > 0
        tweet.links.push(*new_links)
      end
      empty_links = tweet.links.select{ |link| link.url.to_s.strip == "" }
      tweet.links -= empty_links
    end

    user = data["user"]
    u = User.first(:user_id => user["id"]) || User.new(
                                                       :user_id => user["id"],
                                                       :name => user["name"],
                                                       :screen_name => user["screen_name"]
                                                       )
    tweet.user = u

    tweet.save!
    u.tweets << tweet
    u.save!
    tweet
  end

  def retweet_of
    parent_tweet
  end

  def retweet?
    !parent_tweet.nil?
  end

  #private

  RX_RETWEET = /\bRT\b.*@\s*([a-zA-Z0-9_]+)?(?::)?(.*)/i

  def retweet_match
    text.match(RX_RETWEET)
  end

  def is_retweet?
    retweet_match ? true : false
  end

  def retweet_user
    if captures = retweet_match
      if captures[1]
        User.first(:screen_name => captures[1].strip)
      else
        nil
      end
    end
  end

  def retweet_text
    if captures = retweet_match
      captures[2].strip
    end
  end

  def calc_retweet_of
    # ResolveLink.exec "select * from tweets inner join users on tweets.user_id = users.user_id where tweets.text = #{q retweet_text} AND users.screen_name = #{q retweet_user}"
    if is_retweet? && u = retweet_user
      possibles = u.tweets.map{ |tweet| [tweet, Similarity.similarity(tweet.text, self.text)]}.sort_by{ |t, s| -s}
      t = possibles.first
      if t[1] > 0.5
        t[0]
      else
        nil
      end
    else
      nil
    end
  end

  def calc_retweets
    # results = exec "select * from tweets where text RLIKE 'RT\s+@#{origin.first.user.screen_name}' AND text RLIKE '.*#{Regexp.quote(origin.first.text)}.*'"
    links.tweets(:conditions => ["text RLIKE ?", "RT\s+@#{user.screen_name}.*#{Regexp.quote(text)}.*"])
  end

end

