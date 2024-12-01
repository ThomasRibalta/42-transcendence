require 'json'
require 'em-http-request'

class PongApi

  def initialize(logger = Logger.new)
    @logger = logger
  end

  def create_game(api_url, player1, player2, type, &callback)
    http = EM::HttpRequest.new(api_url).post(
      body: { player1: player1, player2: player2, type: type }.to_json,
      head: { 'Content-Type' => 'application/json' }
    )
    http.callback do
      if http.response_header.status == 200
        callback.call(JSON.parse(http.response)) if callback
      else
        callback.call(nil) if callback
      end
    end
  
    http.errback do
      callback.call(nil) if callback
    end
  end

  def get_game_history(api_url, user_id, &callback)
    http = EM::HttpRequest.new(api_url).post(
      body: { user_id: user_id }.to_json,
      head: { 'Content-Type' => 'application/json' }
    )
  
    http.callback do
      if http.response_header.status == 200
        callback.call(JSON.parse(http.response)) if callback
      else
        callback.call(nil) if callback
      end
    end
  
    http.errback do
      callback.call(nil) if callback
    end
  end

  def end_game(api_url, player1, player2, player1_pts, player2_pts, game_id, type, &callback)
    http = EM::HttpRequest.new(api_url).post(
      body: { player1: player1.to_i, player2: player2.to_i, player1_pts: player1_pts,
      player2_pts: player2_pts, game_id: game_id, type: type }.to_json,
      head: { 'Content-Type' => 'application/json' }
    )
    http.callback do
      if http.response_header.status == 200
        callback.call(true) if callback
      else
        callback.call(false) if callback
      end
    end
  
    http.errback do
      callback.call(false) if callback
    end
  end

  def get_tournament(api_url, tournament_id, &callback)
    http = EM::HttpRequest.new("#{api_url}/#{tournament_id}").get(
      head: { 'Content-Type' => 'application/json' }
    )
    http.callback do
      if http.response_header.status == 200
        callback.call(JSON.parse(http.response)) if callback
      else
        callback.call(nil) if callback
      end
    end
  
    http.errback do
      callback.call(nil) if callback
    end
  end

  def start_tournament(api_url, id, jwt, &callback)
    http = EM::HttpRequest.new(api_url).get(
      head: { 'Content-Type' => 'application/json', 'Cookie' => "access_token=#{jwt}"}
    )
    http.callback do
      if http.response_header.status == 200
        callback.call(true) if callback
      else
        callback.call(false) if callback
      end
    end
  
    http.errback do
      callback.call(false) if callback
    end
  end

  def end_tournament(api_url, id, id_winner, &callback)
    http = EM::HttpRequest.new("#{api_url}/#{id}").delete(
      head: { 'Content-Type' => 'application/json'},
      body: { id_winner: id_winner }.to_json
    )
    http.callback do
      if http.response_header.status == 200
        callback.call(true) if callback
      else
        callback.call(false) if callback
      end
    end
  
    http.errback do
      callback.call(false) if callback
    end
  end
  
end