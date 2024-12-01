require_relative '../repository/validation_repository'
require_relative '../services/mail_manager'
require_relative '../config/security'
require 'securerandom'
require 'time'
require 'uri'
require 'net/http'
require 'json'

class ValidationManager

  def initialize(validation_repository = ValidationRepository.new, mail_manager = MailManager.instance, logger = CustomLogger.new)
    @validation_repository = validation_repository
    @mail_manager = mail_manager
    @logger = logger
  end

  def generate_validation(user)
    @logger.log('ValidationManager', "Generating validation for user with email #{user['email']}")
    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, '0')
    activation_info = {
      user_id: user['id'],
      token: code,
      expire_at: (Time.now + 5 * 60).strftime("%Y-%m-%d %H:%M:%S"),
      updated_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
    }
    validation = @validation_repository.get_validation_by_user_id(user['id'])
    if validation.length > 0
      @logger.log('ValidationManager', "Validation already exists for user with email #{user['email']}")
      @validation_repository.update_validation(activation_info)
      @logger.log('ValidationManager', "Validation updated")
    else
      @validation_repository.register_validation(activation_info)
    end
    @logger.log('ValidationManager', "Sending email to user with email #{user['email']}")
    @mail_manager.send_email(
      from: 'transcendence42perpi@gmail.com',
      to: user['email'],
      subject: 'Validation code',
      body: "Your validation code is: #{code}"
    )
    @logger.log('ValidationManager', "Email sent")
  end

  def validate(user_id, code)
    validation = @validation_repository.get_validation_by_user_id(user_id)
    if validation.length == 0
      return {code: 404, error: 'User not found'}
    end
    @logger.log('AuthManager', "Token: #{validation[0]['token']}, Body token: #{code}")
    if validation[0]['token'] != code
      return {code: 401, error: 'Invalid token'}
    end
    if Time.now > Time.parse(validation[0]['expire_at'])
      return {code: 401, error: 'Token expired'}
    end
    return {code: 200, success: 'Token is valid'}
  end
end
