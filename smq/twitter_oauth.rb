#!/usr/bin/env ruby

# OAuth client for Twitter Streaming API
# See http://dev.twitter.com/pages/streaming_api_concepts

## requires
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require 'logutil'
require 'config'

require 'rubygems'
# http://github.com/igrigorik/em-http-request
require 'em-http'
# our patches (in ./lib)
require 'em-http-request-client'
require 'oauth'
require 'oauth/client/em_http'
require 'mq'

## config
config_file = ARGV[0]
if config_file.nil?
  abort "usage: twitter_oauth config.yml"
end
AppConfig = ConfigHelper.load_config(config_file)

# Consumer key and secret for BBC R&D Twitter ingest system.
# Application registered with twitter under the bbcrd_in_samp account.
# See http://twitter.com/oauth_clients/details/183642

consumer = OAuth::Consumer.new(
                               AppConfig[:consumer_key],
                               AppConfig[:consumer_secret],
                               :site => "http://twitter.com"
                               )

access_token = OAuth::AccessToken.new(
                                      consumer,
                                      AppConfig[:access_token],
                                      AppConfig[:token_secret]
                                      )
$signal = false

Signal.trap('INT') { puts "INT!"; $signal = true; AMQP.stop {  EM.stop }}
Signal.trap('TERM') { puts "TERM!"; $signal = true; AMQP.stop {  EM.stop }}

## ChunkHandler - takes chunks, outputs full messages
class ChunkHandler
  attr_accessor :count

  def initialize(limit = 1000, &block)
    @limit = limit
    @block = block
    @count = 0
    @buffer = ''
    @time = Time.now
  end

  def put(chunk)
    if chunk.size > 0
      ## deal with partial tweets
      fragments = chunk.split(/(\r)/)
      while frag = fragments.shift
        if frag == "\r"
          ## publish to queue
          # logger.debug buffer
          @block.call(@buffer)
          @count += 1
          if @count % @limit == 0
            new_time = Time.now
            logger.info "#{@count} tweets published to queue #{@limit.to_f/(new_time - @time)}/sec"
            @time = new_time
          end
          # rate limit
          if AppConfig[:delay]
            sleep AppConfig[:delay]
          end
          @buffer = ''
        else
          @buffer << frag
        end
      end
    end
  end
end

Thread.abort_on_exception = true

CONNECTION_BACKOFF = 1
NETWORK_BACKOFF_INCREMENT = 0.25
network_backoff = 0.25
http_backoff = 10

loop do
  logger.info "loop start"
  break if $signal

  EM.run do
    logger.info "EM start"
    AMQP.start(:host => AppConfig[:host]) do

      logger.info "AMQP start"
      amq = MQ.new
      queue = amq.queue(AppConfig[:queue])

      logger.info "Requesting: #{AppConfig[:url]}"
      request = EventMachine::HttpRequest.new(AppConfig[:url])
      http = request.get(:proxy => AppConfig[:proxy]) do |client|
        consumer.sign!(client, access_token)
      end

      chunk_handler = ChunkHandler.new(AppConfig[:report_limit]) { |tweet| queue.publish(tweet) }
      http.stream do |chunk|
        chunk_handler.put(chunk)
      end

      http.callback do
        logger.info "Response: #{http.response} Code: #{http.response_header.status}"
        if http.response_header.status != 200
          if http_backoff >= 240
            logger.info "Exiting"
            $signal = true
          else
            logger.info "http_backoff: #{http_backoff}"
            sleep http_backoff
            logger.info "http_backoff done"
            # exponential backoff
            http_backoff += http_backoff
            logger.info "Restarting"
          end
        else
          logger.info "http backoff 200: #{CONNECTION_BACKOFF}"
          # restart loop after connection close
          sleep CONNECTION_BACKOFF
          logger.info "http backoff 200 done"
          logger.info "Restarting"
        end
        logger.info "#{chunk_handler.count} tweets published to queue"
        AMQP.stop { EM.stop }
      end

      http.errback do
        logger.info "Error: #{http.errors.inspect}"
        if network_backoff >= 16.0
          logger.info "Exiting"
          $signal = true
        else
          logger.info "network_backoff: #{network_backoff}"
          sleep network_backoff
          logger.info "network_backoff done"
          # linear backoff
          network_backoff += NETWORK_BACKOFF_INCREMENT
          logger.info "Restarting"
        end
        logger.info "#{chunk_handler.count} tweets published to queue"
        AMQP.stop { EM.stop }
      end
    end
  end
end
logger.info "Exit"
