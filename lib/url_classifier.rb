module UrlClassifier
  extend self

  DISCARD = ["", "1", "2", "hi", "-", "rss", "go"]

  def maybe_capitalize(word)
    case word
    when "and"
      word
    else
      word.capitalize
    end
  end

  def guess_metadata_from_url_path(url)
    url = URI.parse(url)
    elements = url.path.split(/\//)
    # pp elements
    while DISCARD.include?(elements.first)
      elements.shift
    end
    # pp elements
    result = elements.first
    if result
      result = result.split(/_/).map{ |x| maybe_capitalize(x) }.join(' ')
    end
    result
  end

  def classify_link(url)
    case url
    when /election_2010/i
      "Election 2010"
    when /zhongwen/i
      "China"
    when /world\/([^\/]+)/i
      $1
    else
      guess_metadata_from_url_path(url)
    end
  end
end
