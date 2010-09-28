$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'doodle'
require 'doodle/datatypes'
require 'net/smtp'
require 'time'
# require 'datatypes'
require 'smtp_tls'

# note: translated from Florian Frank's example in dslkit [http://dslkit.rubyforge.org/]

class Mail < Doodle
  doodle do
    string :mail_server, :default => ENV['MAILSERVER'] || 'mail'
    string :body
    email :from do
      default do
        if ENV['USER']
          ENV['USER'] + '@' + mail_server
        else
          'from@example.com'
        end
      end
    end
    email :to
    string :subject, :default => 'Test Email'
    date :date do
      default { Time.now.rfc2822 }
    end
    string :message_id do
      default do
        key = [ ENV['HOSTNAME'] || 'localhost', $$ , Time.now ].join
        (::Digest::MD5.new << key).to_s
      end
    end
    string :msg do
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
  end

  def send_message
    if true
      puts msg
    else
      ::Net::SMTP.start(mail_server, 25) do |smtp|
        smtp.send_message msg, from, to
      end
    end
  end
end

require 'highline/import'
def prompt_for_password
  p [:pfp, caller]
  ask("Enter your password:  ") { |q| q.echo = '*' }
end

class GMail < Mail
  has :mail_server, :default => 'smtp.gmail.com'
  has :port, :default => 587
  has :username, :default => 'sean.ohalpin@gmail.com'
#  has :password, :default => 'sesame'
  has :password do
    init do
      prompt_for_password
    end
  end
  has :host, :default => 'localhost.localdomain'
  has :message_format, :default => 'plain'

  def send_message
    puts msg
    return
    ::Net::SMTP.start(mail_server,
                      port,
                      host,
                      username,
                      password,
                      message_format) do |smtp|
      smtp.send_message(msg, from, to)
    end
  end
end

GMail do
  subject subject + ': Hi!'
  to 'sean.ohalpin@gmail.com'
  body <<BODY
Hi,

this is a test email from Ruby.

BODY
end.send_message
