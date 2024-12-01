require_relative '../repository/user_repository'
require_relative '../log/custom_logger'
require_relative '../services/validation_manager'
require_relative '../config/security'
require_relative '../services/token_manager'
require 'securerandom'
require 'uri'
require 'net/http'
require 'json'

class AuthManager

  def initialize(
    user_repository = UserRepository.new,
    logger = CustomLogger.new,
    validation_manager = ValidationManager.new,
    security = Security.new,
    token_manager = TokenManager.new(logger)
  )
    @user_repository = user_repository
    @logger = logger
    @validation_manager = validation_manager
    @security = security
    @token_manager = token_manager
  end

  def register_complement_info(user_id)
    @logger.log('AuthManager', "Registering complement info for user with id #{user_id}")
    history = {
      user_id: user_id,
      nb_win: 0,
      nb_win_tournament: 0,
      nb_lose: 0,
      nb_game: 0,
      rank_points: 0,
      updated_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
    }
    @user_repository.register_complement_info(history)
    @logger.log('AuthManager', "Complement info for user with id #{user_id} registered")
  end

  def register_user_42(user)
    @logger.log('AuthManager', "Registering user #{user}")
    user42 = @user_repository.get_user_by_email(user['email'])
    if user42.length > 0
      @logger.log('AuthManager', "User with email #{user['email']} already exists in database, proceeding to login")
      @validation_manager.generate_validation(user42[0])
      return { code: 200, user: user42[0]}
    end
    user_info = {
      username: user['login'],
      email: user['email'],
      img_url: user["image"]["link"],
      role: 0,
      login_type: 1,
      updated_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
    }
    @user_repository.register_user_42(user_info)
    user42 = @user_repository.get_user_by_email(user['email'])
    if user42.length == 0
      return { code: 500, error: 'Error while registering user' }
    end
    register_complement_info(user42[0]['id'])
    @validation_manager.generate_validation(user42[0])
    return { code: 200, user: user42[0] }
  end

  def register(body)
    @logger.log('AuthManager', "Registering new user : #{body['email']}")
    if body.nil? || body.empty?
      return { code: 400, error: 'Invalid body' }
    end
    if body['username'].nil? || body['username'].size < 3 || body['username'].size > 12
      return { code: 400, error: 'Invalid username' }
    end
    email_regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
    if body['email'].nil? || body['email'].size < 5 || body['email'].size > 320 || !body['email'].match(email_regex)
      return { code: 400, error: 'Invalid email' }
    end
    if body['password'].nil? || body['password'].size < 6 || body['password'].size > 255
      return { code: 400, error: 'Invalid password' }
    end
    if body['password'] != body['password_confirmation']
      return { code: 400, error: 'Passwords do not match' }
    end
    if @user_repository.get_user_by_email(body['email']).length > 0
      @logger.log('AuthManager', "Email already in use")
      return { code: 400, error: 'Email already in use' }
    end
    user_info = {
      username: body['username'],
      email: body['email'],
      password: @security.secure_password(body['password']),
      role: 0,
      login_type: 0,
      updated_at: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
    }
    @user_repository.register(user_info)
    user = @user_repository.get_user_by_email(body['email'])
    if user.length == 0
      return { code: 500, error: 'Error while registering user' }
    end
    register_complement_info(user[0]['id'])
    @validation_manager.generate_validation(user[0])
    return { code: 200, success: 'User registered', user: user[0] }
  end

  def login(body)
    @logger.log('AuthManager', "Logging in user")
    if body.nil? || body.empty?
      return { code: 400, error: 'Invalid body' }
    end
    @logger.log('AuthManager', "Email: #{body['email']}")
    if body['email'].nil? || body['email'].empty?
      return { code: 400, error: 'Email is required' }
    end
    if body['password'].nil? || body['password'].empty?
      return { code: 400, error: 'Password is required' }
    end
    user = @user_repository.get_user_by_email(body['email'])
    @logger.log('AuthManager', "User: #{user}")
    if user.length == 0
      return { code: 404, error: 'User not found' }
    end
    if (@security.verify_password(body['password'], user[0]['password'])) == false
      return { code: 401, error: 'Invalid password' }
    end
    @validation_manager.generate_validation(user[0])
    return { code: 200, success: 'User logged in', user: user[0] }
  end

  def validate_code(user_id, code)
    validation_result = @validation_manager.validate(user_id, code)
    if validation_result[:code] != 200
      return validation_result
    end
    user = @user_repository.get_user_by_id(user_id).first

    return { code: 200, success: "Token valid", user: user }
  end

  def get_user_info(client, access_token)
    @logger.log('AuthManager', "Getting user info with access token: #{access_token}")
    uri = URI.parse("https://api.intra.42.fr/v2/me")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code == '200'
      @logger.log('AuthManager', "User info retrieved successfully")
      user_info = JSON.parse(response.body)
      return user_info
    else
      @logger.log('AuthManager', "Error while getting user info: #{response.message}")
      return nil
    end
  end

  # Get access token from 42 API using authorization code
  def get_access_token(client, authorization_code)
    @logger.log('AuthManager', "Getting access token with authorization code: #{authorization_code}")
    uri = URI.parse("https://api.intra.42.fr/oauth/token")

    params = {
      grant_type: 'authorization_code',
      client_id: ENV['API_CLIENT'],
      client_secret: ENV['API_SECRET'],
      code: authorization_code,
      redirect_uri: 'https://localhost/callback-tmp'
    }

    response = Net::HTTP.post_form(uri, params)

    if response.is_a?(Net::HTTPSuccess)
      @logger.log('AuthManager', "Access token retrieved successfully")
      response_body = JSON.parse(response.body)
      access_token = response_body['access_token']
      access_token
    else
      @logger.log('AuthManager', "Error while getting access token: #{response.message}")
      nil
    end
  end

end
