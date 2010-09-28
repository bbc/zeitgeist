$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))
require 'doodle'
require 'doodle/rfc822'
require 'net/smtp'
require 'time'

# note: translated from Florian Frank's example in dslkit [http://dslkit.rubyforge.org/]

class Mail < Doodle
  has :mail_server, :default => ENV['MAILSERVER'] || 'mail'
  has :body, :kind => String

  has :from, :kind => String do
    default do
      if ENV['USER']
        ENV['USER'] + '@' + mail_server
      else
        'from@example.com'
      end
    end
    must 'be valid email address' do |s|
      s =~ RFC822::EmailAddress
    end
  end

  has :to, :kind => String do
    must 'be valid email address' do |s|
      s =~ RFC822::EmailAddress
    end
  end
  has :subject, :default => 'Test Email'
  has :date do
    default { Time.now.rfc2822 }
  end
  has :message_id do
    default do
      key = [ ENV['HOSTNAME'] || 'localhost', $$ , Time.now ].join
      (::Digest::MD5.new << key).to_s
    end
  end
  has :msg, :kind => String do
    default do
      [
       "From: #{from}",
       "To: #{to}",
       "Subject: #{subject}",
       "Date: #{date}",
       "Message-Id: <#{message_id}@#{mail_server}>",
       '',
       body
      ] * "\n"
    end
  end

  def send
    if true
      puts msg
    else
      ::Net::SMTP.start(mail_server, 25) do |smtp|
        smtp.send_message msg, from, to
      end
    end
  end
end

def mail(&block)
  Mail.new(&block)
end

def prompt
  return 'someone@example.com'
  STDOUT.print "Send to? "
  STDOUT.flush
  STDIN.gets.strip
end

m = Mail do
  subject subject + ': Hi!'
  if rcpt = prompt
    to rcpt
  end
  body "Hello, world!\n"
end
m.send
