require 'uri'
require_relative '../log/custom_logger'
require_relative '../config/request_helper'
require_relative '../services/tournament_manager'
require_relative '../services/token_manager'

class TournamentController
  def initialize(logger = Logger.new, tournament_manager = TournamentManager.new, token_manager = TokenManager.new)
    @logger = logger
    @tournament_manager = tournament_manager
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
      @logger.log('TournamentController', "Error parsing URI: #{e.message}")
      RequestHelper.not_found(client)
      return
    end

    query_string = uri.query
    params = query_string ? URI.decode_www_form(query_string).to_h : {}
    clean_path = uri.path
    tournament_match = clean_path.match(%r{^/api/tournament/(\d+)$})
    if tournament_match
      tournament_id = tournament_match[1]
      case [method]
      when ['GET']
        get_tournament(client, tournament_id)
      when ['PUT']
        update_tournament(client, tournament_id, body)
      when ['DELETE']
        delete_tournament(client, tournament_id, body)
      else
        return 1
      end
    elsif clean_path == '/api/tournament/create'
      case [method]
      when ['POST']
        create_tournament(client, body, cookies)
      else
        return 1
      end
    elsif clean_path == '/api/tournaments/'
      case [method]
      when ['GET']
        get_tournaments(client)
      else
        return 1
      end
    elsif clean_path == '/api/tournament/start'
      case [method]
      when ['GET']
        start_tournament(client)
      else
        return 1
      end
    else
      return 1
    end
    return 0
  end

  def start_tournament(client)
    RequestHelper.respond(client, 200, {success: 'Tournament started'}.to_json)
  end

  def get_tournament(client, tournament_id)
    @logger.log('TournamentController', "Get tournament #{tournament_id}")
    tournament = @tournament_manager.get_tournament(tournament_id)
    if tournament[:error]
      RequestHelper.respond(client, 404, { error: 'Tournament not found' })
      return
    end
    RequestHelper.respond(client, 200, tournament)
  end

  def get_tournaments(client)
    tournaments = @tournament_manager.get_tournaments()
    RequestHelper.respond(client, 200, tournaments)
  end

  def create_tournament(client, body, cookies)
    user_id = @token_manager.get_user_id(cookies['access_token']);
    tournament = @tournament_manager.create_tournament(body, user_id)
    if tournament[:error]
      RequestHelper.respond(client, 400, tournament)
      return
    end
    RequestHelper.respond(client, 200, tournament)
  end

  def update_tournament(client, tournament_id, body)
    user_id = @token_manager.get_user_id(cookies['access_token']);
    tournament = @tournament_manager.update_tournament(tournament_id, body, user_id)
    if tournament[:error]
      RequestHelper.respond(client, 400, tournament)
      return
    end
    RequestHelper.respond(client, 200, tournament)
  end

  def delete_tournament(client, tournament_id, body)
    tournament = @tournament_manager.delete_tournament(tournament_id, body)
    if tournament[:error]
      RequestHelper.respond(client, 400, tournament)
      return
    end
    RequestHelper.respond(client, 200, tournament)
  end

end