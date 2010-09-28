## Link
require 'json'
require 'resolve_link'
require 'dm-types'
require 'dm-validations'
require 'pp'
require 'url_classifier'

class Link
  def self.reload; Kernel.load __FILE__; end

  include DataMapper::Resource
  include DBObject
  include ResolveLink
  extend ResolveLink

  extend UrlClassifier

  has n, :tweets, :through => Resource

  property :id, Serial
  property :url, String, :length => 255, :unique => true, :index => true, :required => true

  # this didn't create the index - I did this directly on the database
  # CREATE UNIQUE index idx_links_url ON links(url);

  property :section, String, :length => 255
  property :media_type, String, :length => 255
  property :metadata, Json

  # property :heading, String, :length => 255
  # property :description, Text, :lazy => false
  # property :original_publication_date, Date

  property :first_tweeted_at, Time

  validates_present :url

  before :save, :update_metadata

  def update_metadata
    # p [:updating_metadata, caller]
    begin
      metadata = extract_metadata(self.url)

      # BBC News hack
      if metadata[:headline]
        if metadata[:headline].to_s.strip == "INDEX"
          metadata[:headline] = metadata[:title]
        end
      end
      if self.url == "http://www.bbc.co.uk/news/"
        metadata[:description] = "BBC News"
      end

      # p [:metadata, metadata]
      self.metadata = metadata
      self.section = self.class.section(self)
      # p self.metadata
      self.media_type = metadata[:prototyping][:media_type]
      # self.heading = metadata["headline"] || metadata["title"]
      # self.original_publication_date = metadata["originalpublicationdate"]
      # self.description = metadata["description"]
      self.first_tweeted_at = tweets.first(:order => :created_at).created_at

    rescue => e
      p [:error, "Updating metadata for #{self.url}", e, e.backtrace]
    end
  end

#link_map = Link.all(:conditions => ["metadata like ?", "%30_ Moved%"])
#link_map.each do |link| link.fixup_duplicate; end

  def fixup
    real_url = resolve_link(self.url)
    if self.url != real_url
      if real_link = Link.first(:url => real_url)
        existing_links = repository.adapter.select("SELECT * FROM link_tweets WHERE link_id = #{self.id}")
        existing_links.each do |link|
          p link
          duplicate_links = repository.adapter.select("SELECT * FROM link_tweets WHERE link_id = #{real_link.id} AND tweet_twid = #{link.tweet_twid}")
          pp duplicate_links
          duplicate_links.each do |duplicate_link|
            repository.adapter.execute("DELETE FROM link_tweets WHERE link_id = #{duplicate_link.link_id} AND tweet_twid = #{duplicate_link.tweet_twid}")
          end
        end
        sql = "UPDATE link_tweets SET link_id = #{real_link.id} WHERE link_id = #{self.id}"
        puts sql
        begin
          repository.adapter.execute(sql)
        rescue DataObjects::IntegrityError => e
          if e.to_s =~ /Duplicate entry/
            puts "Duplicate - ignore"
            # TODO delete entry
          else
            raise
          end
        end
        # update metadata
        real_link.save
      else
        self.url = real_url
        save
      end
    end
  end

  def self.fixup_all_duplicates
    self.all do |link|
      link.fixup
    end
  end

  # def section
  #   self.class.section(self)
  # end

  def self.section(link)
    result = nil
    if link.metadata
      result = link.metadata[:section]
    end
    if result.nil?
      result = classify_link(link.url)
    end
    if result.nil?
      result = "Misc"
    end
    result
  end

  def doc
    doc_for_url(url)
  end

end

