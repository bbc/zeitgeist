#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '../lib/load_paths')
require LoadPath.app_path("db")
require 'pony'
require 'shellwords'
require 'date_format'

include ERB::Util

emails = ConfigHelper.load_config("feedback-emails.yml")

def Pony.sendmail_binary
  "/usr/sbin/sendmail"
end

template =<<EOT
Feedback from Twitter Zeitgeist
===============================
#{Time.now}
-------------------------------
<% feedbacks.each do |feedback| %>
Name:  <%=h feedback.name %>
Email: <%=h feedback.email %>
At:    <%= ::DateFormat.format_datetime(feedback.created_at) %>
Comments:
<%=h feedback.comments.chomp %>

-------------------------------
<% end %>
EOT

feedbacks = Feedback.all(:processed => false)
if feedbacks.size > 0
  body = ErbBinding.erb(template, :feedbacks => feedbacks)

  Pony.mail(
            :to      => emails.map{|x| Shellwords.escape(x)}.join(','),
            :from    => "feedback@zeitgeist.prototyping.bbc.co.uk",
            :body    => body,
            :subject => "Feedback digest for #{Time.now}"
            )

  feedbacks.each do |fb|
    fb.processed = true
    fb.save
  end
end

# sudo env RUBYOPT=-rubygems ruby scripts/email-feedback.rb
