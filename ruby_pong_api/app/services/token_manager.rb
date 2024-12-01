require 'jwt'
require 'json'

class TokenManager
  SECRET_KEY = ENV['SECRET_KEY']

  def initialize(logger = Logger.new)
    @logger = logger
  end


  def get_user_id(token)
    if token.nil?
      @logger.log('TokenManager', 'Token is nil')
      return nil
    end
    payload = decode(token)
    user_id = payload['user_id']
    return user_id
  end

  private

  def decode(token)
    begin
      decoded = JWT.decode(token.split(' ').last, SECRET_KEY, true, { algorithm: 'HS256' })
      decoded[0]
    rescue JWT::ExpiredSignature
      @logger.log('TokenManager', 'Token has expired')
      nil
    rescue JWT::DecodeError => e
      @logger.log('TokenManager', "Token decode error: #{e.message}")
      nil
    end
  end
  
end
