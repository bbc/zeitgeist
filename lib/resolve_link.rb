## requires
# resolve links by following through redirects
# gem "json", "> 1.2"
require 'json'
require 'net/http'
require 'nokogiri'
require 'ostruct'
require 'pp'
require 'url_helpers'
require 'rack/utils'
require 'url_classifier'
require 'net-http-protocol'
require 'config'
# this is no use - detects £ in utf-8 (\302\243) as iso-8859-2
#require 'rchardet'

if RUBY_VERSION < '1.8.7'
  require 'backports'
end

## ResolveLink
module ResolveLink
  include UrlHelpers
  include UrlClassifier

  extend self
  def self.reload; Kernel.load(__FILE__); end
  RX_URL = %r{\b((?:[\w-]+://?|www[.])[^\s()<>]+(?:\(?:[\w\d]+\)|(?:[^[:punct:]\s]|/)))}
  MAX_LEVEL = 5

  ## set up proxy
  if ENV['http_proxy']
    Proxy = ENV['http_proxy'] ? URI.parse(ENV['http_proxy']) : OpenStruct.new
    HTTP = Net::HTTP::Proxy(Proxy.host, Proxy.port, Proxy.user, Proxy.password)
  else
    HTTP = Net::HTTP
  end

  ## deworm(url)
  def deworm(url)
    url.gsub(%r{(https?:/).*?(/(www|news).bbc.co.uk/.*)}, '\\1\\2')
  end

  ## fix_url
  # fix urls where user has concatenated a word to beginning of http:, e.g. ashtaghttp://www.bbc.co.uk/...
  def fix_url(u)
    if u
      begin
        u.gsub(/(.*)?(h?ttps?:.*)/, "\\1 \\2")
        if $2
          $2.gsub(/^ttp/, 'http')
        else
          "http:/#{u}"
        end
      rescue => e
        p [:fixurl, u, e]
        u
      end
      u
    end
  end

  ## normalize_url(url)
  def normalize_url(url)
    # strip trailing slash (for normalization - not for web standards)
    url.strip.chomp("/")
  end

  ## special_case(uri)
  # handle any common nasty specific cases

  ### Facebook links:
  #
  #   <h3 class="GenericStory_Message"
  #   data-ft="{&quot;type&quot;:&quot;msg&quot;}"><a
  #   class="GenericStory_Name"
  #   href="http://www.facebook.com/ZopaUK">Zopa</a> <a
  #   href="http://www.bbc.co.uk/iplayer/episode/b00s5gd0/The_One_Show_23_04_2010/"
  #   target="_blank" rel="nofollow"
  #   onmousedown="UntrustedLink.bootstrap($(this), &quot;&quot;,
  #   event)">
  #
  # OR
  #
  #   <div class="UIMediaItem"><a
  #   href="http://www.bbc.co.uk/iplayer/episode/b00s5gd0/The_One_Show_23_04_2010/"
  #   class="" id="" title="" target="_blank" onclick="" style=""
  #   rel="nofollow" onmousedown="UntrustedLink.bootstrap($(this),
  #   &quot;&quot;, event)"><div class="UIMediaItem_Wrapper">
  #
  # OR
  #
  #   <div class="UIStoryAttachment_Title"><a
  #   href="http://www.bbc.co.uk/iplayer/episode/b00s5gd0/The_One_Show_23_04_2010/"
  #   class="" id="" title="" target="_blank" onclick="" style=""
  #   rel="nofollow" onmousedown="UntrustedLink.bootstrap($(this),
  #   &quot;&quot;, event)">
  #

  def special_case(uri)
    case uri
    when %r{http://news\.google\.com/news/url}
      # news.google.com does not do an HTTP redirect - returns a 200 and
      # javascript to set window.location - bad google
      parse_params(URI.parse(uri).query)["url"].first
    else
      uri
    end
  end

  # FIXME: move bitly stuff to own module
  # TODO: config items
  bitly_config = ConfigHelper.load_config("bitly.yml")
  BITLY_LOGIN = bitly_config[:login]
  BITLY_API_KEY = bitly_config[:api_key]

  BITLY_API_DOMAIN = "api.bit.ly"
  BITLY_HTTP = HTTP.new(BITLY_API_DOMAIN, 80)
  # BITLY_HTTP.set_debug_output $stderr
  BITLY_EXPAND_PATH = "/v3/expand"

  def resolve_bitly_links(uris)
    long_urls = []
    begin
      #p [:resolve_bitly_links, 1]
      params = {
        :shortUrl => uris,
        :login => BITLY_LOGIN,
        :apiKey => BITLY_API_KEY,
        :format => "json"
      }
      #p [:resolve_bitly_links, 2]
      url = [BITLY_EXPAND_PATH, encode_params(params)].join("?")
      #puts url
      #p [:resolve_bitly_links, 3]
      response = BITLY_HTTP.get(url)
      body = response.body
      #p [:resolve_bitly_links, 4]
      if response.code == "200"
        #p [:resolve_bitly_links, 5]
        data = JSON.parse(body)
        #p [:resolve_bitly_links, 6, data]
        #p [:resolve_bitly_links, 6.1, data["status_code"]]
        if data["status_code"].to_s != "200"
          p [:resolve_bitly_links, 6.2, data]
        else
          #p [:resolve_bitly_links, 6.3]
          long_urls = data["data"]["expand"].map{|x|
            #p x
            [x["short_url"], x["long_url"]]
          }
        end
      else
        begin
          #p [:resolve_bitly_links, 7]
          data = JSON.parse(body)
          p [:resolve_bitly_links, 8, data]
        rescue => e
          p [:resolve_bitly_links, 9, e, body]
        end
      end
    rescue => e
      p [:resolve_bitly_links, 10, e]
    end
    #p [:resolve_bitly_links, 11]
    long_urls
  end

  ## resolve_link(uri, level = 0)
  def resolve_link(uri, level = 0, host = nil)
    #p [:resolve, uri, level, host]
    stage = 0
    begin
      # I had code here to strip the trailing slash but that turned
      # out to be not such a good idea - BBC often (but not always)
      # redirects urls without trailing / to ones with which means we
      # end up in an endless redirect loop... :S the problem then is
      # that we can't normalize urls - we don't know if we're pointing
      # at a file or directory
      stage = 1
      uri = fix_url(uri)
      if level > MAX_LEVEL
        p [:resolve_link, uri, "Too many redirects", level]
        nil
      else
        stage = 2
        #p [:special_case]
        uri = special_case(uri)
        stage = 3
        p_uri = URI.parse(uri)
        #p [:parsed, p_uri, p_uri.host]
        stage = 4
        if p_uri.host !~ %r{bbc.co.uk$}
          stage = 4.1
          old_uri = uri
          stage = 4.2
          uri = deworm(uri)
          #p [:dewormed, old_uri, uri]
          stage = 4.3
          p_uri = URI.parse(uri)
          stage = 4.4
          host = p_uri.host
        end
        stage = 5
        if host.nil?
          scheme = p_uri.scheme || "http"
          host = p_uri.scheme + "://" + p_uri.host
        end
        stage = 6
        http = HTTP.new(p_uri.host, p_uri.port)
        # p [:path, p_uri.path]
        stage = 7
        if p_uri.path == ""
          path = "/"
        else
          path = p_uri.path
        end
        stage = 8
        path = [path, p_uri.query].compact.join("?")
        #p [:path, path]
        stage = 9
        res = http.head(path)
        #p res
        #p res.code
        code = res.code.to_i
        stage = 10
        if (200...300).include?(code)
          stage = 10.1
          canonicalize(uri)
        elsif (300...400).include?(code)
          stage = 10.2
          uri = res.header["location"]
          #p [:redirect, uri]
          if uri !~ /http:/
            stage = 10.21
            uri = File.join("http://#{p_uri.host}", uri)
          end
          #p [:after_300, uri]
          stage = 10.3
          u = URI.parse(uri)
          if u.host =~ /bbc.co.uk$/
            stage = 10.31
            canonical_uri = canonicalize(uri)
            stage = 10.32
            #p [:canonical_uri, canonical_uri]
            resolve_link(canonical_uri, level + 1, host)
          else
            stage = 10.33
            # recursively call ourselves to resolve next level of redirection
            uri = u.to_s
            if u.host.nil?
              stage = 10.331
              uri = "http://#{uri}"
              u = URI.parse(uri)
              stage = 10.332
              host = u.host
            end
            stage = 10.34
            resolve_link(uri, level + 1, host)
          end
        elsif (400...500).include?(code)
          stage = 10.4
          p [:host, host, :code, code, :uri, uri]
          if uri =~ %r{/www\.bbc\.co\.uk/mobile/iplayer}
            stage = 10.41
            # try to find real link
            # TODO: remember came from mobile
            uri = uri.gsub(%r{/mobile}, '')
            stage = 10.42
            p [:resolving_mobile_url_to, uri]
            resolve_link(uri, 0, host)
          end
        else
          p [:bad_uri, uri, level, code, res]
          nil
        end
      end
    rescue => e
      p [:resolve_links, stage, uri, e]
    end
  end

  # FIXME: move these methods to own module

  ## get_image_from_page(doc)
  # various ad-hoc xpaths (based on pages seen) to extract a useful image
  XPATHS = [
            [:video, "//noscript/img[@name='holdingImage']"], # video
            [:news, "//td[@class='storybody']/table/tr/td/div/img"],
            [:news, "//td[@class='storybody']/table//img"],
            [:news, "//td[@class='storybody']/*/img"],
            [:news, "//td[@class='storybody']//img"],
            [:news, "//div[@class='g-container story-body']//img"], # news
            [:blog, "//div[@class='post']//img[1]"],                # blog
            [:feature, "//div[@class='feature']//img[1]"],          # e.g. 1xtra
            [:programme, "//div[@class='img-zoom']/img[1]"],        # e.g. /programmes 1xtra & some others
           ]

  def get_image_from_page(doc)
    image_url = nil
    media_type = nil
    XPATHS.each do |mtype, xpath|
      img = doc.xpath(xpath)
      #pp [xpath, img]
      if img.size > 0
        img = img.first
        image_url = img.attributes["src"].text
        if image_url !~ /^http/
          image_url = File.join("http://www.bbc.co.uk", image_url)
        end
        media_type = mtype
        break
      end
    end
    [media_type, image_url]
  end

  ## get_slideshow_image(url)
  def get_slideshow_image(url)
    get_slideshow_image_for_doc(doc_for_url(url))
  end

  ## get_slideshow_image_for_doc(doc)
  def get_slideshow_image_for_doc(doc)
    begin
      slideshow_url = get_slideshow_url(doc)
      if slideshow_url
        get_slideshow_image_from_slideshow(slideshow_url)
      else
        nil
      end
    rescue => e
      p [:error, "getting slideshow image", e, url]
      nil
    end
  end

  ## get_slideshow_url(doc)
  def get_slideshow_url(doc)
    media_url_rx = %r{http://downloads.bbc.co.uk/news/nol/shared/spl/hi/audio_slideshow/(?:.*)/content}
    match = doc.xpath("//script").text.match(media_url_rx)
    if match
      match[0]
    else
      nil
    end
  end

  ## get_slideshow_image_from_slideshow(url)
  # pass url of slideshow directory (use get_slideshow_url(doc) to extract from HTML doc)
  def get_slideshow_image_from_slideshow(url)
    content_url = File.join(url, "soundslide.xml")
    doc = doc_for_uri(content_url)
    slide_filename = doc.xpath("//slides/slide[1]/file").text
    File.join(url, "custom", slide_filename)
  end

  ## get_image_for_url
  def get_image_for_url(uri)
    get_image_from_page(doc_for_uri(uri))
  end

  ## http_get
  def http_get(uri)
    parsed_uri = URI.parse(uri)
    http       = HTTP.new(parsed_uri.host, parsed_uri.port)
    page       = http.get(parsed_uri.path)
  end

  ## doc_for_uri
  def doc_for_uri(uri)
    page = http_get(uri)
    doc  = Nokogiri::HTML(page.body)
  end
  alias :doc_for_url :doc_for_uri

  def transcode_metadata(metadata, encoding)
    #pp metadata
    metadata.keys.each do |key|
      value = metadata[key]
      # p [:key, key, :value, value]
      if value.kind_of?(Hash)
        value = transcode_metadata(value, encoding)
      else
        #cd = CharDet.detect(value)
        #metadata[key] = Iconv.conv("utf-8", cd[:encoding], value)
        # hack to fix pound £ signs on badly marked up BBC pages
        #p [:key, key, :value, value]
        metadata[key] = value.to_s.gsub(/([\302-\377])\302\243/, "\\1\243")
        if metadata[key].match(/([^\302-\377])\243/)
          p [:converting_to_utf8]
          metadata[key] = Iconv.conv("utf-8", "iso-8859-1", value)
        end
      end
    end
  end

  ## extract_metadata(uri)
  def extract_metadata(uri)
    doc = doc_for_uri(uri)
    metadata = {
      :prototyping => {
        :media_type => "html"
      }
    }
    head = doc.xpath("/html/head")
    ## NOTE interesting fact: BBC News pages have title in iso-8859-1 but
    # NOTE rest of metadata in UTF-8; meta encoding set to iso-8859-1
    # NOTE looks like one system does the titles and another the metadata...
    # NOTE ...except for international pages, e.g. Spanish, which have encoding in utf-8
    head.xpath("meta").each do |meta|
      key = meta.attributes["name"]
      if key
        if content = meta.attributes["content"]
          metadata[key.text.downcase.to_sym] = content.text
        end
      end
    end

    ## FIXME this doesn't capture every case, e.g.
    # - http://news.bbc.co.uk/sport1/hi/football/teams/p/portsmouth/8634140.stm
    # - http://news.bbc.co.uk/1/hi/scotland/8634158.stm
    # - http://news.bbc.co.uk/1/hi/entertainment/8629934.stm
    # - http://news.bbc.co.uk/sport1/hi/football/eng_prem/8636703.stm
    # - http://news.bbc.co.uk/1/hi/england/8632331.stm
    title = head.xpath("title")
    if title.size > 0
      metadata[:title] = title.text
    end
    if metadata[:section]
      metadata[:section] = metadata[:section].split(/-/).map{ |word| maybe_capitalize(word)}.join(' ')
    end

    #puts "BEFORE"
    #pp metadata

    media_type, image = get_image_from_page(doc)

    if image
      metadata[:prototyping][:media_type] = media_type
    end

    if metadata[:thumbnail_url].nil? && metadata["thumbnail_url"].nil?
      metadata[:thumbnail_url] = image
    end

    if slideshow_image = get_slideshow_image_for_doc(doc)
      metadata[:prototyping][:slideshow_image] = slideshow_image
      metadata[:prototyping][:media_type] = "slideshow"
      metadata[:thumbnail_url] ||= slideshow_image
    end

    #p [:transcoding, doc.encoding]
    transcode_metadata(metadata, doc.encoding)

    metadata
  end
end

__END__

## Notes
### Detect media type
#### Videos

<noscript>
  <img name="holdingImage" class="holding" src="http://newsimg.bbc.co.uk/media/images/47702000/jpg/_47702297_beachbottle.jpg" alt="Plastic on Kamilo Beach" />

    <object width="0" height="0">
    <param name="id" value="embeddedPlayer_8639769" />
    <param name="width" value="512" />
    <param name="height" value="288" />
    <param name="holding" value="http://newsimg.bbc.co.uk/media/images/47702000/jpg/_47702297_beachbottle.jpg" />
    <param name="playlist" value="http://news.bbc.co.uk/media/emp/8630000/8639700/8639769.xml" />
    <param name="config_settings_autoPlay" value="true" />
    <param name="config_settings_showPopoutButton" value="false" />
    <param name="autoPlay" value="true" />
    <param name="config_plugin_fmtjLiveStats_pageType" value="eav1" />
    <param name="config_plugin_fmtjLiveStats_edition" value="Domestic" />
    <param name="fmtjDocURI" value="/1/hi/in_depth/8639769.stm"/>
    <param name="config_settings_showUpdatedInFooter" value="true" />
 		</object>

### Classify
#### By top level directory

