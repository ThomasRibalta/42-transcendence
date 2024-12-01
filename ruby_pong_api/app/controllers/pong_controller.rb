require 'uri'
require_relative '../log/custom_logger'
require_relative '../config/request_helper'
require_relative '../services/pong_manager'

class PongController
  def initialize(logger = Logger.new, pong_manager = PongManager.new)
    @logger = logger
    @pong_manager = pong_manager
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
    user_id_stats_match = clean_path.match(%r{^/api/pong/player/stats/(\d+)$})
    if user_id_stats_match
      user_id = user_id_stats_match[1]
      case [method]
      when ['GET']
        get_user_stats(client, user_id)
      else
        return 1
      end
    else
      case [method, clean_path]
      when ['POST', '/api/pong/create_game']
        create_game(client, body)
      when ['POST', '/api/pong/get_game_history']
        get_game_history(client, body)
      when ['POST', '/api/pong/end_game']
        end_game(client, body)
      else
        return 1
      end
    end
    return 0
  end

  def get_user_stats(client, user_id)
    @logger.log('PongController', "Getting stats for user #{user_id}")
    if user_id.nil?
      RequestHelper.respond(client, 400, { error: 'Missing user_id' })
      return
    end
    stats = @pong_manager.get_user_stats(user_id)
    if stats.nil?
      RequestHelper.respond(client, 404, { error: 'User not found' })
      return
    end
    RequestHelper.respond(client, 200, { stats: stats })
  end

  def create_game(client, cookies)
    status = @pong_manager.create_game(cookies)
    if status[:code] != 200
      RequestHelper.respond(client, status[:code], { error: status[:message] })
      return
    end
    RequestHelper.respond(client, 200, { game_info: status[:game_info], success: status[:message] })
  end

  def get_game_history(client, cookies)
    in_game = @pong_manager.is_already_playing(cookies["user_id"])
    if in_game.nil?
      RequestHelper.respond(client, 404, { no_game: 'No game found' })
      return
    end
    RequestHelper.respond(client, 200, { game_info: in_game[:game_info], success: 'Game found' })
  end

  def end_game(client, body)
    status = @pong_manager.end_game(body)
    if status[:code] != 200
      RequestHelper.respond(client, status[:code], { error: status[:message] })
      return
    end
    RequestHelper.respond(client, 200, { success: status[:message] })
  end
end