require_relative '../services/token_manager'
require_relative '../log/custom_logger'

class TokenController
  def initialize(logger = CustomLogger.new, token_manager = TokenManager.new(logger), user_manager = UserManager.new)
    @logger = logger
    @token_manager = token_manager
    @user_manager = user_manager
  end

  def route_request(client, method, path, body, headers, cookies)
    if path.nil? || path.empty?
      RequestHelper.not_found(client)
      return
    end

    begin
      uri = URI.parse(path)
    rescue URI::InvalidURIError => e
      @logger.log('TokenController', "Error parsing URI: #{e.message}")
      RequestHelper.not_found(client)
      return
    end

    query_string = uri.query
    params = query_string ? URI.decode_www_form(query_string).to_h : {}
    clean_path = uri.path

    case [method, clean_path]
    when ['POST', '/api/auth/refresh']
      refresh_tokens(client, cookies)
    when ['GET', '/api/auth/logout']
      logout(client)
    when ['GET', '/api/auth/verify-token-user']
      verify_token_user(client, headers, cookies)
    when ['GET', '/api/auth/verify-token-user-code']
      verify_token_user_code(client, headers, cookies)
    when ['GET', '/api/auth/verify-token-admin']
      verify_token_admin(client, headers, cookies)
    else
      return 1
    end
    return 0
  end

  def logout(client)
    RequestHelper.respond(client, 200, { success: 'Logout.' }, ["access_token=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0", "refresh_token=; HttpOnly; SameSite=Strict; Path=/; Max-Age=0"])
  end

  def refresh_tokens(client,  cookies)
    @logger.log('TokenController', "cookie #{cookies}")
    refresh_token = cookies['refresh_token']
    tokens = @token_manager.refresh_tokens(refresh_token)
    if tokens.nil?
      RequestHelper.respond(client, 401, { error: 'Invalid refresh token.' })
      return
    end
    access_token = tokens[:access_token]
    refresh_token = tokens[:refresh_token]
    RequestHelper.respond(client, 200, {success: 'Re generation token'}, ["access_token=#{access_token}; Path=/; Max-Age=3600; HttpOnly; Secure", "refresh_token=#{refresh_token}; Path=/; Max-Age=604800; HttpOnly; Secure"])
  end

  def verify_token_user(client, headers, cookies)
    authorization_header = cookies['access_token']
    payload = @token_manager.verify_access_token(authorization_header)
    if payload.nil?
      RequestHelper.respond(client, 401, { error: "Invalid access token." })
      return
    end
    user = @user_manager.get_user(payload['user_id'])
    if user[:error]
      RequestHelper.respond(client, 401, { error: "Invalid access token." })
      return
    end
    RequestHelper.respond(client, 200, { success: "Access token is valid.", user_id: payload['user_id'], username: user[:user][0]["username"] })
  end

  def verify_token_user_code(client, headers, cookies)
    authorization_header = cookies['access_token']
    payload = @token_manager.verify_token_user_code(authorization_header)
    if payload.nil?
      RequestHelper.respond(client, 401, { error: "Invalid access token." })
      return
    end
    RequestHelper.respond(client, 200, { success: "Access token is valid (state can be false)." })
  end

  def verify_token_admin(client, headers, cookies)
    authorization_header = cookies['access_token']
    payload = @token_manager.verify_admin_token(authorization_header)
    if payload.nil?
      RequestHelper.respond(client, 401, { error: "Invalid access token." })
      return
    end
    RequestHelper.respond(client, 200, { success: "Admin access token is valid." })
  end
end
