#!/bin/sh
# Gems that have compiled extensions
if [ "$http_proxy" = "" ]; then
  PROXY=""
else
  PROXY="-p $http_proxy"
fi
GEMS="nokogiri thin rack rack-cache rack-contrib em-http-request fastthread json amqp do_mysql bluepill"
sudo gem install $GEMS $PROXY --no-ri --no-rdoc
