## requires
require 'rack/utils'
require 'uri'

## UrlHelpers
module UrlHelpers
  extend self

  def uri_escape(text)
    Rack::Utils.escape(Rack::Utils.unescape(text.to_s))
  end

  ## canonicalize(uri)
  def canonicalize(uri)
    uri = URI.parse(uri)
    if uri.path == ""
      uri.path = "/"
    end
    if uri.host =~ /bbc\.co\.uk/
      uri.query = nil
    end
    uri.to_s
  end

  ## group_params(uri)
  def group_params(params)
    params.each_slice(2).group_by{|x, y| x}.map{|x, y| [x, y.map{|z| z[1]}]}.flatten(1)
  end

  ## parse_params(query)
  def parse_params(query)
    Hash[*group_params(query.
                       gsub(/^\?/, '').
                       split(/&/).
                       map{ |kv|
                         kv.
                         split(/=/).
                         map{ |x| URI.unescape(x)}}.
                       flatten)
        ]
  end

  ## encode_params(params)
  def encode_params(params)
    params.map {|key, values|
      if !values.kind_of?(Array)
        values = [values]
      end
      values.map {|value| [uri_escape(key), uri_escape(value)].join('=') }
    }.sort.join('&')
  end

  FN_BLANK = lambda {|x| x.nil? or x.empty?}

  ## url_with_params(url, params = {})
  # adds key=value pairs to url
  def url_with_params(url, params = { })
    url, existing_params = url.split(/\?/)
    encoded_params = encode_params(params)
    #p [:url, url, :params, existing_params, :encoded_params, encoded_params]
    [url, [existing_params, encoded_params].reject(&FN_BLANK).join('&')].reject(&FN_BLANK).join('?')
  end

  ## path_encode_params(params)
  def path_encode_params(params)
    params.map {|key, values|
      if !values.kind_of?(Array)
        values = [values]
      end
      values.map {|value| [uri_escape(key), uri_escape(value)].join('/') }
    }.sort.join('/')
  end

  ## url_with_path(url, params = {})
  # adds /key/value pairs to url
  def url_with_path(url, params = { })
    url, existing_params = url.split(/\?/)
    encoded_params = path_encode_params(params)
    #p [:url, url, :params, existing_params, :encoded_params, encoded_params]
    [File.join(url, encoded_params), [existing_params].reject(&FN_BLANK).join('&')].reject(&FN_BLANK).join('?')
  end

end
