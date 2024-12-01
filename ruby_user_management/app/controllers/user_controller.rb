require_relative '../services/token_manager'
require_relative '../log/custom_logger'
require_relative '../services/user_manager'
require 'uri'
require 'net/http'
require 'json'

class UserController

  def initialize(logger = CustomLogger.new, user_manager = UserManager.new, token_manager = TokenManager.new)
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
      puts "Erreur lors de l'analyse de l'URI : #{e.message}"
      RequestHelper.not_found(client)
      return
    end
    query_string = uri.query
    params = query_string ? URI.decode_www_form(query_string).to_h : {}
    clean_path = uri.path
    user_id_match = clean_path.match(%r{^/api/user/(\d+)$})
    user_page_match = clean_path.match(%r{^/api/users/(\d+)$})
    if user_id_match
      user_id = user_id_match[1]
      case [method]
      when ['GET']
        get_user(client, user_id)
      when ['PUT']
        update_user(client, body, cookies, user_id)
      when ['DELETE']
        delete_user(client, user_id, cookies)
      else
        @logger.log('UserController', "No route found for: #{method} #{clean_path}")
        RequestHelper.not_found(client)
      end
    elsif user_page_match
      user_page = user_page_match[1]
      case [method]
      when ['GET']
        get_users_paginated(client, user_page)
      end
    else
      return 1
    end
    return 0
  end

  def get_users_paginated(client, user_page=1)
    status = @user_manager.get_users_paginated(user_page)
    if status[:code] != 200
      RequestHelper.respond(client, status[:code], { error: status[:error] })
      return
    end
    RequestHelper.respond(client, status[:code], { users: status[:users], nPages: status[:nPages] })
  end
  
  def get_user(client, user_id)
    status = @user_manager.get_user(user_id)
    RequestHelper.respond(client, status[:code], status)
  end

  def update_user(client, body, cookies, user_id_match)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    status = @user_manager.update_user(user_id, body, user_id_match)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success]})
  end

  def delete_user(client, user_id_match, cookies)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    status = @user_manager.delete_user(user_id, user_id_match)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success]})
  end

end
