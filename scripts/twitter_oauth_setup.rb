#!/usr/bin/env ruby
# Copied from http://gist.github.com/524376
# Related blog post: http://matt.west.co.tt/ruby/migrating-ruby-twitter-apps-to-oauth/

# Command line util for acquiring a one-off Twitter OAuth access token
# Based on http://blog.beefyapps.com/2010/01/simple-ruby-oauth-with-twitter/

require 'rubygems'
require 'oauth'

puts <<EOS
Set up your application at https://twitter.com/apps/ (as a 'Client' app),
then enter your 'Consumer key' and 'Consumer secret':

Consumer key:
EOS
consumer_key = STDIN.readline.chomp
puts "Consumer secret:"
consumer_secret = STDIN.readline.chomp

consumer = OAuth::Consumer.new(
	consumer_key,
	consumer_secret,
	{
		:site => 'http://twitter.com/',
		:request_token_path => '/oauth/request_token',
		:access_token_path => '/oauth/access_token',
		:authorize_path => '/oauth/authorize'
	})

request_token = consumer.get_request_token

puts <<EOS
Visit #{request_token.authorize_url} in your browser to authorize the app,
then enter the PIN you are given:
EOS

pin = STDIN.readline.chomp
access_token = request_token.get_access_token(:oauth_verifier => pin)

puts <<EOS
Congratulations, your app has been granted access! Use the following config:

TWITTER_CONSUMER_KEY = '#{consumer_key}'
TWITTER_CONSUMER_SECRET = '#{consumer_secret}'
TWITTER_ACCESS_TOKEN = '#{access_token.token}'
TWITTER_ACCESS_SECRET = '#{access_token.secret}'

And use the following code to connect to Twitter:

require 'twitter'
auth = Twitter::OAuth.new(TWITTER_CONSUMER_KEY, TWITTER_CONSUMER_SECRET)
auth.authorize_from_access(TWITTER_ACCESS_TOKEN, TWITTER_ACCESS_SECRET)
client = Twitter::Base.new(auth)

EOS
