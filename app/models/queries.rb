## requires
require File.join(File.dirname(__FILE__), '../../lib/load_paths')
require 'datamapper'
require 'time'
require 'quotes'

$DEBUG_SQL = false

## SQLHelper
module SQLHelper
  include Quotes
  extend self

  ## canonical_date(date)
  def canonical_date(date)
    case date
    when String
      date = Date.parse(date)
    when Numeric
      date = Date.new(date)
    when Time
      date = Date.parse(date.xmlschema)
    end
    date.strftime("%Y-%m-%d")
  end

  ## format_date_clause(date)
  def format_date_clause(date)
    case date
    when Range, Array
      "BETWEEN #{q canonical_date(date.first)} AND #{q canonical_date(date.last)}"
    else
      " = #{q canonical_date(date)}"
    end
  end

  ## format_clause(params, clause, delim = " ")
  def format_clause(params, clause, delim = " ")
    if params.key?(clause)
      params = params[clause]
      if !params.kind_of?(Array)
        params = [params]
      end
      params = params.flatten.compact
      if params.size > 0
        "#{clause.to_s.upcase.gsub(/_/, ' ')} #{params.join(" #{delim} ")}"
      else
        ""
      end
    else
      nil
    end
  end

  ## make_sql(params)
  def make_sql(params)
    select   = format_clause(params, :select, ',')
    from     = format_clause(params, :from)
    where    = format_clause(params, :where, 'AND')
    group_by = format_clause(params, :group_by, ',')
    having   = format_clause(params, :having, 'AND')
    order_by = format_clause(params, :order_by, ',')
    limit    = format_clause(params, :limit)
    [select, from, where, group_by, having, order_by, limit].compact.join("\n")
  end
end

module ZipMap
  extend self
  ## zipmap(array, array_of_lambdas)
  # apply array of lambdas to list
  def zipmap(array, array_of_lambdas)
    array.zip(array_of_lambdas).map{ |v, m| m.call(v)}
  end
end

## add zipmap to Enumerable
module Enumerable
  ## zipmap(array_of_lambdas)
  # apply array of lambdas to list
  def zipmap(array_of_lambdas)
    ZipMap.zipmap(self, array_of_lambdas)
  end
end

## Query
module Query
  include SQLHelper
  extend self

  ## defaults
  ### FIXME: config items
  DEFAULT_LIMIT = 10

  ### list of bbc accounts to exclude from results
  BBC_TWEETERS = [
                  'on_bbc1',
                  'on_bbc2',
                  'on_bbc3',
                  'on_bbc4',
                  'on_radio1',
                  'on_radio1_extra',
                  'on_radio2',
                  'on_radio3',
                  'on_radio4',
                  'on_5live',
                  'on_5live_sport',
                  'on_6music',
                  'on_asiannetwork',
                  'on_bbc7',
                  'on_cbbc',
                  'on_cbeebies',
                  'on_news24',
                  'on_parliament',
                  'on_worldservice'
                 ]

  ## exec(sql)
  # execute sql and return array of Structs
  def exec(sql)
    puts sql if $DEBUG_SQL
    resolve_metadata(repository(:default).adapter.select(sql))
  end

  ## default_exclusion_clause
  # exclude bbc tweeters
  # exclude non-bbc links
  def default_exclusion_clause
    [
     "(screen_name NOT IN (#{BBC_TWEETERS.map{ |x| q(x)}.join(',')}))",
     # "links.url rlike '^http://([a-z]+\\.)?bbc.co.uk/'",
    ]
  end

  ## table_joins
  # joins all tables together
  def table_joins
    sql = <<ESQL
links
  INNER JOIN
link_tweets ON link_id = links.id
  INNER JOIN
tweets ON link_tweets.tweet_twid = twid
  INNER JOIN
users ON tweets.user_id = users.user_id
ESQL
  end

  ## format_results(dataset)
  COLUMN_FORMATTERS = {
    "day" => proc { |x| x.strftime("%Y-%m-%d")},
    "url" => proc { |x| x },
    "total" => proc { |x| x },
  }

  ## resolve_metadata(results)
  # parse metadata for full set of results
  def resolve_metadata(results)
    if results.first.respond_to?(:metadata)
      results.each do |row|
        case row.metadata
        when String
          row.metadata = JSON.parse(row.metadata)
        when NilClass
          row.metadata = { }
        end
      end
    end
    results
  end

  ## format_results(dataset)
  def format_results(dataset)
    columns = dataset[0].members
    formatters = COLUMN_FORMATTERS.values_at(*columns)
    dataset.map{|r| ZipMap.zipmap(r, formatters)}
  end

  ## total_links_by_url(date, options = {:threshold => nil, :limit => DEFAULT_LIMIT})
  # >> pp format_results(total_links_by_url(dates, :threshold => 16))
  def total_links_by_url(date, options = { })
    options = { :threshold => nil, :limit => DEFAULT_LIMIT }.merge(options)
    params = {
      :select   => [:url, :section, :media_type, :metadata, :first_tweeted_at, "COUNT(*) AS total" ],
      :from     => table_joins,
      :where    => [default_exclusion_clause, "DATE(created_at) #{format_date_clause(date)}", options[:where]],
      :group_by => [:url, :section, :media_type, :metadata, :first_tweeted_at ],
      :order_by => "total desc",
      :limit    => options[:limit]
    }
    if options[:threshold]
      params[:having] = "total > #{options[:threshold]}"
    end
    sql = make_sql(params)
    if options[:debug]
      puts sql
    end
    exec(sql)
  end

  ## total_links_by_url_by_date(date, options = {:threshold => nil, :limit => DEFAULT_LIMIT })
  # >> pp format_results(total_links_by_url_by_date(dates, :threshold => 16))
  def total_links_by_url_by_date(date, options = { })
    options = { :threshold => nil, :limit => DEFAULT_LIMIT }.merge(options)
    if options[:threshold]
      threshold = "total > #{options[:threshold]}"
    end
    params = {
      :select   => [:url, :section, :media_type, :metadata, "DATE(created_at) AS day", "COUNT(*) AS total"],
      :from     => table_joins,
      :where    => [default_exclusion_clause],
      :group_by => [:url, :section, :media_type, :day],
      :having   => ["day #{format_date_clause(date)}", threshold],
      :order_by => [:day, "total desc"],
      :limit    => options[:limit]
    }
    sql = make_sql(params)
    exec(sql)
  end

  ## total_links_for_url_by_date(url, date, options = {:threshold => nil, :limit => DEFAULT_LIMIT })
  # >> pp format_results(total_links_for_url_by_date("http://news.bbc.co.uk/", dates, 16))
  def total_links_for_url_by_date(url, date, options = { })
    options = { :threshold => nil, :limit => DEFAULT_LIMIT }.merge(options)
    if options[:threshold]
      threshold = "total > #{options[:threshold]}"
    end
    params = {
      :select   => [:url, :section, :media_type, "DATE(created_at) AS day", "COUNT(*) AS total", "metadata"],
      :from     => table_joins,
      :where    => [default_exclusion_clause, "url = #{q(url)}"],
      :group_by => [:url, :section, :media_type, :day],
      :having   => ["day #{format_date_clause(date)}", threshold],
      :order_by => [:day, "total desc"],
      :limit    => options[:limit]
    }
    sql = make_sql(params)
    exec(sql)
  end

  ## total_links_by_date(date, options = { :limit => DEFAULT_LIMIT })
  # >> pp format_results(total_links_by_date(dates))
  def total_links_by_date(date, options = { })
    options = { :limit => DEFAULT_LIMIT }.merge(options)
    params = {
      :select   => ["DATE(created_at) AS day", "COUNT(*) AS total"],
      :from     => table_joins,
      :where    => [default_exclusion_clause],
      :group_by => :day,
      :having   => "day #{format_date_clause(date)}",
      :order_by => [:day, :total],
      :limit    => options[:limit]
    }
    sql = make_sql(params)
    exec(sql)
  end

  ## tweets_for_url_by_date(url, options = { :limit => DEFAULT_LIMIT })
  def tweets_for_url_by_date(url, options = { })
    options = { :limit => DEFAULT_LIMIT }.merge(options)
    params = {
      :select   => [:twid, :url, :screen_name, :text, :created_at, :parent_tweet_twid],
      :from     => table_joins,
      :where    => [default_exclusion_clause, "url = #{q(url)}"],
      :order_by => ["created_at desc"],
      :limit    => options[:limit]
    }
    sql = make_sql(params)
    if options[:debug]
      puts sql
    end
    exec(sql)
  end

end

__END__
## NOTES
### Excluded user names:

  +-----------+-----------------+-----------------+-------------+
  |  15282673 | on_radio4       | on_radio4       | 12882078686 |
  |  15368355 | on_worldservice | on_worldservice | 12881631362 |
  |  15725545 | on_bbc1         | on_bbc1         | 12882077569 |
  |  15727649 | on_bbc2         | on_bbc2         | 12882078198 |
  |  15727943 | on_bbc3         | on_bbc3         | 12864154228 |
  |  15727995 | on_news24       | on_news24       | 12878608929 |
  |  15728181 | on_cbbc         | on_cbbc         | 12882572593 |
  |  15728237 | on_cbeebies     | on_cbeebies     | 12882824297 |
  |  15728322 | on_parliament   | on_parliament   | 12882825265 |
  |  15728366 | on_bbc4         | on_bbc4         | 12864154560 |
  |  15734508 | on_radio1       | on_radio1       | 12878610020 |
  |  15734526 | on_radio2       | on_radio2       | 12881330281 |
  |  15734541 | on_radio3       | on_radio3       | 12881330880 |
  |  15734557 | on_5live        | on_5live        | 12881331804 |
  |  15734570 | on_5live_sport  | on_5live_sport  | 12876334004 |
  |  15734589 | on_6music       | on_6music       | 12878611304 |
  |  15734609 | on_bbc7         | on_bbc7         | 12882825845 |
  |  15734635 | on_radio1_extra | on_radio1_extra | 12878612455 |
  |  15734663 | on_asiannetwork | on_asiannetwork | 12878612891 |
  |  39219024 | Peter Hindmarsh | on_line_writer  | 12659091859 |
  | 133030290 | Adam Wilson     | on_cbeebies18   | 12745902175 |
  | 136527402 | Adam Wilson     | on_cbbc18       | 12787559389 |
  | 136778041 | Adam Wilson     | on_cbeebies19   | 12804581507 |
  +-----------+-----------------+-----------------+-------------+

  'on_bbc1',
  'on_bbc2',
  'on_bbc3',
  'on_bbc4',
  'on_radio1',
  'on_radio1_extra',
  'on_radio2',
  'on_radio3',
  'on_radio4',
  'on_5live',
  'on_5live_sport',
  'on_6music',
  'on_asiannetwork',
  'on_bbc7',
  'on_cbbc',
  'on_cbeebies',
  'on_news24',
  'on_parliament',
  'on_worldservice',

### Explain

  EXPLAIN SELECT url , section , media_type , first_tweeted_at , metadata, COUNT(*) AS total
  FROM links
    INNER JOIN
  link_tweets ON link_id = links.id
    INNER JOIN
  tweets ON link_tweets.tweet_twid = twid
    INNER JOIN
  users ON tweets.user_id = users.user_id

  WHERE DATE(tweets.created_at) BETWEEN '2010-05-15' AND '2010-05-21'
  GROUP BY url , section , media_type , first_tweeted_at, metadata
  ORDER BY total desc
  LIMIT 10;

## links by hour:

  SELECT HOUR(created_at) AS hour, COUNT(*) AS total FROM links INNER JOIN link_tweets ON links.id = link_id INNER JOIN tweets ON tweets.twid = tweet_twid WHERE DATE(created_at) = '2010-06-09' GROUP BY hour ORDER BY hour;

### using NOW()

  SELECT HOUR(created_at) AS hour, COUNT(*) AS total FROM links INNER JOIN link_tweets ON links.id = link_id INNER JOIN tweets ON tweets.twid = tweet_twid WHERE DATE(created_at) = DATE(NOW()) GROUP BY hour ORDER BY hour;

  SELECT DATE_FORMAT(created_at, "%Y-%m-%d %H:00") AS hour, COUNT(*) AS total FROM links INNER JOIN link_tweets ON links.id = link_id INNER JOIN tweets ON tweets.twid = tweet_twid WHERE created_at BETWEEN DATE_SUB(NOW(), INTERVAL 24 HOUR) AND NOW() GROUP BY hour ORDER BY hour;

DATE_SUB(NOW(), INTERVAL 24 HOUR)



CREATE PROCEDURE report_24_hours() SELECT DATE_FORMAT(created_at, "%Y-%m-%d %H:00") AS hour, COUNT(*) AS total FROM links INNER JOIN link_tweets ON links.id = link_id INNER JOIN tweets ON tweets.twid = tweet_twid WHERE created_at BETWEEN DATE_SUB(NOW(), INTERVAL 24 HOUR) AND NOW() GROUP BY hour ORDER BY hour;
CALL report_24_hours;
