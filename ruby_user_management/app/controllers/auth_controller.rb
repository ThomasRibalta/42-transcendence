require_relative '../services/token_manager'
require_relative '../log/custom_logger'
require_relative '../services/auth_manager'
require_relative '../config/request_helper'
require 'uri'
require 'net/http'
require 'json'

class AuthController

  def initialize(logger = CustomLogger.new, auth_manager = AuthManager.new, token_manager = TokenManager.new)
    @logger = logger
    @auth_manager = auth_manager
    @token_manager = token_manager
  end

  def route_request(client, method, path, body, headers, cookies)
    if path.nil? || path.empty?
      RequestHelper.not_found(client)
      return
    end

    begin
      uri = URI.parse(path)
    rescue URI::InvalidURIError => e
		@logger.log('AuthController', "Error parsing URI: #{e.message}")
		RequestHelper.not_found(client)
    return
    end

    query_string = uri.query
    params = query_string ? URI.decode_www_form(query_string).to_h : {}
    clean_path = uri.path

    case [method, clean_path]
    when ['POST', '/api/auth/register']
      register(client, body)
    when ['POST', '/api/auth/login']
      login(client, body)
    when ['GET', '/api/auth/logwith42']
      logwith42(client)
    when ['POST', '/api/auth/callback']
      handle_callback(client, body)
	  when ['POST', '/api/auth/validate-code']
		  validate_code(client, body, headers, cookies)
    else
      return 1
    end
    return 0
  end

  def handle_callback(client, body)
    authorization_code = body['code']
    if authorization_code
      access_token = @auth_manager.get_access_token(client, authorization_code)
      if access_token
        user = @auth_manager.get_user_info(client, access_token)
        if user
          status = @auth_manager.register_user_42(user);
          access_token = @token_manager.generate_access_token(status[:user]['id'], false, status[:user]['role'])
          RequestHelper.respond(client, 200, {success: 'Successfully connected !' }, ["access_token=#{access_token}; Path=/; Max-Age=3600; HttpOnly; Secure"])
        else
          RequestHelper.respond(client, 500, {error:'Failed to fetch user info'})
        end
      else
        RequestHelper.respond(client, 500, {error:'Failed to obtain access token'})
      end
    else
      RequestHelper.respond(client, 400, {error:'Authorization failed'})
    end
  end


  def logwith42(client)
    redirect_url = ENV['REDIR_URL']
    client.write "HTTP/1.1 302 Found\r\n"
    client.write "Location: #{redirect_url}\r\n"
    client.write "\r\n"
  end

  def register(client, body)
    status = @auth_manager.register(body)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    access_token = @token_manager.generate_access_token(status[:user]["id"], false, status[:user]["role"])
    RequestHelper.respond(client, status[:code], {success: status[:success]}, ["access_token=#{access_token}; Path=/; Max-Age=3600; HttpOnly; Secure"])
  end

  def login(client, body)
    status = @auth_manager.login(body)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    access_token = @token_manager.generate_access_token(status[:user]["id"], false, status[:user]["id"])
    RequestHelper.respond(client, status[:code], {success: status[:success]}, ["access_token=#{access_token}; Path=/; Max-Age=3600; HttpOnly; Secure"])
  end

  def validate_code(client, body, headers, cookies)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    token = body['token']
    status = @auth_manager.validate_code(user_id, token)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    token = @token_manager.generate_tokens(status[:user]["id"], true, status[:user]["role"])
    access_token = token[:access_token]
    refresh_token = token[:refresh_token]
    RequestHelper.respond(client, status[:code], {success: status[:success]}, ["access_token=#{access_token}; Path=/; Max-Age=3600; HttpOnly; Secure", "refresh_token=#{refresh_token}; Path=/; Max-Age=604800; HttpOnly; Secure"])
  end

end
