require 'mail'
require 'singleton'

class MailManager
  include Singleton

  def initialize
    Mail.defaults do
      delivery_method :smtp, {
        address: 'smtp.gmail.com',
        port: 587,
        user_name: ENV['EMAIL'],
        password: ENV['EMAIL_PASSWORD'],
        authentication: :plain,
        enable_starttls_auto: true
      }
    end
	@logger = CustomLogger.new
  end

  def send_email(from:, to:, subject:, body:)
    mail = Mail.new do
      from    from
      to      to
      subject subject
      body    body
    end

    mail.deliver!
  rescue StandardError => e
    @logger.log('MailManager', "Error sending email: #{e.message}")
  end
end
