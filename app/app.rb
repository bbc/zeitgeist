## requires
require "sinatra"
require "pp"
require 'json'
require 'time_ago'
require 'hashtags'
require 'date_format'
require 'escape_xml'
require 'url_helpers'
require 'logger'
require 'doodle'
require 'code_timer'

require LoadPath.app_path("db")
require LoadPath.model_path("queries")

## logger
def logger
  @logger ||= Logger.new(STDOUT)
end

## true when accessible on internet but should not be available to public
PROTECT_ALL = false

## ZeitgeistApp
class ZeitgeistApp < Sinatra::Base
  include Query
  include EscapeXML
  include UrlHelpers

  set :public, LoadPath.base_path("public")
  set :static, true             # serve up static files if found

  ## app helpers
  helpers do
    include CodeTimer

    ## format_heading(text) - capitalize each word of text
    def format_heading(text)
      text = Rack::Utils.unescape(text.to_s).split.map{ |x| UrlClassifier.maybe_capitalize(x) }.join(" ")
      case text
      when "Iplayer"
        "iPlayer"
      when "Tv"
        "TV"
      when "Uk"
        "UK"
      when "Us and Canada"
        "US and Canada"
      when "Worldservice"
        "World Service"
      else
        text
      end
    end

    ## cache(seconds) - set cache header
    def cache(seconds)
      if authorized?
        headers['Cache-Control'] = "max-age=#{seconds},must-revalidate"
      else
        headers['Cache-Control'] = "public,max-age=#{seconds}"
      end
    end

    ## protected!
    def protected!
      unless authorized?
        p [:requesting_authentication]
        response['WWW-Authenticate'] = %(Basic realm="BBC R&D Prototyping Zeitgeist")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    ## authorized?
    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      # Note: it is intended that auth is handled by Apache/nginx -
      # this code allows you to enter any username/password
      # usernames/passwords should be set in the front end server
      @auth.provided? && @auth.basic? && @auth.credentials
    end

    ## zg_link(url, text, attributes = { }, params = { })
    def zg_link(url, text, attributes = { }, params = { })
      link_to(admin(url, params), text, attributes)
    end

    ## link_to(url, text, attributes = { })
    def link_to(url, text, attributes = { })
      attributes[:href] = url
      %[<a#{encode_attributes(attributes)}>#{h(text)}</a>]
    end

    ## twitter_link(tweet)
    def twitter_link(tweet)
      "http://www.twitter.com/#{Rack::Utils.escape(tweet.screen_name)}/status/#{Rack::Utils.escape(tweet.twid)}"
    end

    ## admin - add admin url
    def admin(url, params = { })
      url_with_path(authorized? ? "/admin#{url}" : url, params)
    end

    ## h - escape html
    def h(*a)
      EscapeXML.normalize(a.join(' '))
    end

    ## links_for_url_grouped_by_hour(url)
    def links_for_url_grouped_by_hour(url)
      link = Link.first(:url => url)
      link.
        tweets.
        group_by {|x| x.created_at.strftime("%Y-%m-%d %H")}.
        map { |key, list| [key, list.size]}.
        sort
    end

    ## chart_counter
    def chart_counter
      @counter ||= 0
      @counter += 1
    end

    ## sections(results)
    def sections(results)
      results.group_by{ |link| link.section }.map{ |key, results| [key, results.inject(0){ |total, row| total + row.total }] }.sort_by{ |row| -row[1]}
    end

    ## recent_tweets
    def recent_tweets
      Tweet.all(:order => [:created_at.desc], :limit => 10)
    end

    ## update_css
    def update_css
      less_file = File.stat(LoadPath.css_path("style.less"))
      css_file = File.stat(LoadPath.css_path("style.css"))
      if less_file.mtime > css_file.mtime
        puts "updating style.css"
        system "cd #{LoadPath.css_path} && lessc style.less"
      end
    end

    def make_key(date, options)
      [date.to_a.map{ |d| d.to_s}.join("-"), options.map{ |k, v| k.to_s + "=" + v.to_s}.sort.join('|')].join('|')
    end

    ## views
    ### link_total_view(date, scope)
    def link_total_view(date, scope)
      cache(60)

      timer("link_total_view", date, scope) do
        content_type 'text/html', :charset => 'utf-8'
        options = { :where => [] }
        if params[:section]
          options[:where] << "section = '#{Rack::Utils.unescape(params[:section])}'"
        end
        if params[:media_type]
          options[:where] << "media_type = '#{Rack::Utils.unescape(params[:media_type])}'"
        end
        options[:debug] = true
        results = timer("total_links_by_url", date, options) do
          results = total_links_by_url(date, options)
        end
        #p [:results, results]

        url_params = ["section", "media_type"].inject({}) {|hash, k| hash[k.to_sym] = params[k] if params[k]; hash }
        base_url = case scope
                   when 'now'
                     "/zeitgeist"
                   when 'by_week'
                     "/zeitgeist/by_week"
                   else
                     "/zeitgeist"
                   end

        timer("erb :zeitgeist") do
          erb :zeitgeist,
          :locals => {
            :link       => nil,
            :results    => results,
            :date       => date,
            :sections   => sections(results),
            :scope      => scope,
            :base_url   => base_url,
            :url_params => url_params
          }
        end
      end
    end

    ### link_total_view_now()
    def link_total_view_now()
      date = [Date.today - 1, Date.today + 1]
      link_total_view(date, "now")
    end

    ### link_total_view_by_week()
    def link_total_view_by_week()
      date = [Date.today - 6, Date.today + 1]
      link_total_view(date, "by_week")
    end

    ### single_url_view(url)
    def single_url_view(url)
      timer("single_url_view", url) do
        link = Link.first(:url => url)
        if link.nil?
          redirect "/zeitgeist/missing_link"
        end

        content_type 'text/html', :charset => 'utf-8'
        cache(60)

        tweets = []

        timer("tweets_for_url_by_date", url) do
          tweets = tweets_for_url_by_date(url, :limit => 5000, :debug => true)
        end

        # for graph
        tweets_grouped_by_hour = tweets.group_by{|x| x.created_at.strftime("%Y-%m-%d %H")}
        grouped_by_hour = tweets_grouped_by_hour.map{ |key, list| [key, list.size]}.sort

        # http://zeitgeist.prototyping.bbc.co.uk/admin/zeitgeist/by_url/http://www.bbc.co.uk/iplayer/console/radio1
        scope = "detail"
        url_params = ["section", "media_type"].inject({}) {|hash, k| hash[k.to_sym] = params[k] if params[k]; hash }
        base_url = case scope
                   when 'now'
                     "/zeitgeist"
                   when 'by_week'
                     "/zeitgeist/by_week"
                   else
                     "/zeitgeist"
                   end

        original_tweets_by_date = []
        retweet_map = {}
        highest_retweets = []

        timer("calc-retweets") do
          # split tweets into those with parents (retweets) and those without (original tweets)
          retweets, original_tweets = tweets.partition{|tweet| tweet.parent_tweet_twid }

          # create hash of original tweet twid => tweet
          parent_tweets = original_tweets.inject({ }) {|h, tweet| h[tweet.twid] = tweet; h }

          # map all retweets to their parent
          part = retweets.map{|x| t = parent_tweets[x.parent_tweet_twid]; t ? [t, x] : [nil, x] }
          retweet_map = part.inject(Hash.new{|h, k| h[k] = []}) {|h, i| h[i[0]] << i[1]; h}

          # which tweets have the highest number of retweets?
          highest_retweets = retweet_map.
            reject{|k, v| k.nil? or k.screen_name.nil?}.
            map{|k, v| [k, v.size]}.
            sort_by{|k, v| -v }

          # sort original tweets by date
          original_tweets_by_date = original_tweets.group_by {|tweet| t = tweet.created_at; Time.local(t.year, t.month, t.day) }.sort.reverse
        end

        timer("single_url_view - rendering", url) do
          erb :zeitgeist_by_url,
          :locals => {
            :link                    => link,
            :grouped_by_hour         => grouped_by_hour,
            :tweets                  => tweets,
            :scope                   => scope,
            :base_url                => base_url,
            :url_params              => url_params,
            :original_tweets_by_date => original_tweets_by_date,
            :retweet_map             => retweet_map,
            :highest_retweets        => highest_retweets,
          }
        end
      end
    end
  end

  before do
    update_css
  end

  ## ROUTES

  ## GET /
  get "/" do
    protected! if PROTECT_ALL
    if authorized?
      redirect "/admin/zeitgeist"
    else
      redirect "/zeitgeist"
    end
  end

  ## GET /zeitgeist
  get "/zeitgeist/?" do
    protected! if PROTECT_ALL
    link_total_view_now
  end

  ## GET /zeitgeist/media_type/:media_type
  get "/zeitgeist/media_type/:media_type/?" do |media_type|
    protected! if PROTECT_ALL
    # p [:media_type, media_type]
    params[:media_type] = media_type
    link_total_view_now
  end

  ## GET /zeitgeist/section/:section
  get "/zeitgeist/section/:section/?" do |section|
    protected! if PROTECT_ALL
    # p [:section, section]
    params[:section] = section
    link_total_view_now
  end

  ## GET /zeitgeist/by_week/
  get "/zeitgeist/by_week/?" do
    protected! if PROTECT_ALL
    link_total_view_by_week
  end

  ## GET /zeitgeist/by_week/media_type/:media_type
  get "/zeitgeist/by_week/media_type/:media_type/?" do |media_type|
    protected! if PROTECT_ALL
    params[:media_type] = media_type
    link_total_view_by_week
  end

  ## GET /zeitgeist/by_week/section/:section
  get "/zeitgeist/by_week/section/:section/?" do |section|
    protected! if PROTECT_ALL
    params[:section] = section
    link_total_view_by_week
  end

  ## GET /admin
  get "/admin/?" do
    redirect "/admin/zeitgeist/"
  end

  ## GET /admin/zeitgeist
  get "/admin/zeitgeist/?" do
    protected!
    link_total_view_now
  end

  ## GET /admin/zeitgeist/media_type/:media_type
  get "/admin/zeitgeist/media_type/:media_type/?" do |media_type|
    protected!
    params[:media_type] = media_type
    link_total_view_now
  end

  ## GET /admin/zeitgeist/section/:section
  get "/admin/zeitgeist/section/:section/?" do |section|
    protected!
    params[:section] = section
    link_total_view_now
  end

  ## GET /admin/zeitgeist/by_date/:date
  get "/admin/zeitgeist/by_date/:date/?" do |date|
    protected!
    date = Date.parse(date)
    link_total_view(date, "by_date")
  end

  ## GET /admin/zeitgeist/by_week
  get "/admin/zeitgeist/by_week/?" do
    protected!
    link_total_view_by_week
  end

  ## GET /admin/zeitgeist/by_week/media_type/:media_type
  get "/admin/zeitgeist/by_week/media_type/:media_type/?" do |media_type|
    protected!
    params[:media_type] = media_type
    link_total_view_by_week
  end

  ## GET /admin/zeitgeist/by_week/section/:section
  get "/admin/zeitgeist/by_week/section/:section/?" do |section|
    protected!
    params[:section] = section
    link_total_view_by_week
  end

  ## GET /admin/zeitgeist/by_url/
  get "/admin/zeitgeist/by_url/*" do
    protected!
    url = Rack::Utils.unescape(params[:splat].join(''))
    single_url_view(url)
  end

  ## GET /admin/zeitgeist/url/
  get "/admin/zeitgeist/url/*" do
    protected!
    url = Rack::Utils.unescape(params[:splat].join(''))
    single_url_view(url)
  end

  ## GET /admin/zeitgeist/media_type/:media_type/url/*
  get "/admin/zeitgeist/media_type/:media_type/url/*" do |media_type|
    protected!
    params[:media_type] = media_type
    url = Rack::Utils.unescape(params[:splat].join(''))
    single_url_view(url)
  end

  ## GET /admin/zeitgeist/section/:section/url/*
  get "/admin/zeitgeist/section/:section/url/*" do |section|
    protected!
    params[:section] = section
    url = Rack::Utils.unescape(params[:splat].join(''))
    single_url_view(url)
  end

  ## GET /feedback
  get %r{(/admin)?/feedback/?} do
    protected! if PROTECT_ALL
    fb = Feedback.new
    erb :feedback, :locals => {
      :scope      => "feedback",
      :url_params => { },
      :link => nil,
      :feedback => fb,
    }
  end

  ## POST /feedback
  post %r{(/admin)?/feedback/?} do
    protected! if PROTECT_ALL
    fields = ["name", "email", "comments"]
    fb_params = fields.inject({ }) {|hash, name| hash[name] = params[name]; hash }
    fb = Feedback.new(fb_params)
    fb.save
    if fb.errors.size > 0
      # p fb.errors
      erb :feedback, :locals => {
        :scope      => "feedback",
        :url_params => { },
        :link => nil,
        :feedback => fb,
      }
    else
      erb :feedback_response, :locals => {
        :scope      => "feedback",
        :url_params => { },
        :link => nil,
        :feedback => fb,
      }
    end
  end

  ## TODO - handle missing link
  ## get /zeitgeist/missing_link
  get "/zeitgeist/missing_link" do
    "It looks like that page no longer exists"
  end

  ## /zeitgeist/date - for diagnostics
  get "/zeitgeist/date" do
    require 'time'
    Time.now.utc.xmlschema
  end

end
