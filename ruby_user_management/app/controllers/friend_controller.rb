require_relative '../services/token_manager'
require_relative '../log/custom_logger'
require_relative '../services/friend_manager'
require_relative '../config/request_helper'
require 'uri'
require 'net/http'
require 'json'

class FriendController

  def initialize(logger = CustomLogger.new, friend_manager = FriendManager.new, token_manager = TokenManager.new)
    @logger = logger
    @token_manager = token_manager
    @friend_manager = friend_manager
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
    friends_match = clean_path.match(%r{^/api/friends/(\d+)$})
    friend_match = clean_path.match(%r{^/api/friend/(\d+)$})
    if friends_match
      friends_id = friends_match[1]
      case [method]
      when ['GET']
        get_friends(client, friends_id)
      end
    elsif friend_match
      friend_id = friend_match[1]
      case [method]
      when ['GET']
        get_friend(client, friend_id, body)
      when ['PATCH']
        update_friends(client, friend_id, cookies, body)
      when ['DELETE']
        delete_friends(client, friend_id, cookies)
      end
    else
      case [method, clean_path]
        when ['POST', '/api/add-friend']
          add_friend(client, body, cookies)
        else
          return 1
        end
    end
    return 0
  end

  def add_friend(client, body, cookies)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    status = @friend_manager.add_friend(user_id, body)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success], friend_id: status[:friend_id], friendship_id: status[:friendship_id],
      friend_name: status[:friend_name]})
  end

  def get_friends(client, user_id)
    friends = @friend_manager.get_friends(user_id)
    RequestHelper.respond(client, 200, friends)
  end

  def update_friends(client, friendship_id, cookies, body)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    status = @friend_manager.update_friends(user_id, friendship_id, body)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success], friend_id: status[:friendship]["requester_id"]})
  end

  def delete_friends(client, friendship_id, cookies)
    user_id = @token_manager.get_user_id(cookies['access_token'])
    status = @friend_manager.delete_friends(user_id, friendship_id)
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success]})
  end

  def get_friend(client, friendship_id, body)
    body = JSON.parse(body) if body.is_a?(String)
    user_id = body["user_id"]
    status = @friend_manager.get_friend(user_id, friendship_id, body["friend_id"])
    if status[:error]
      RequestHelper.respond(client, status[:code], {error: status[:error]})
      return
    end
    RequestHelper.respond(client, status[:code], {success: status[:success]})
  end
end
