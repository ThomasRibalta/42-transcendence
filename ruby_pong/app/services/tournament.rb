require_relative '../log/custom_logger'
require_relative 'external/user_api'
require_relative 'external/pong_api'
require 'tzinfo'
require_relative 'game'

class Tournament

  def initialize(logger = Logger.new, user_api = UserApi.new, pong_api = PongApi.new)
    @logger = logger
    @user_api = user_api
    @pong_api = pong_api
    @tournaments = {}
  end

  def websocket_open(ws)
    ws.instance_variable_get(:@handler).state != :closed
  end
  

  def create_game(client1, client2, tournament_id, type)
    @pong_api.create_game('http://ruby_pong_api:4571/api/pong/create_game', client1[:player]["id"], client2[:player]["id"], type) do |status|
      if status
        game = Game.new(client1, client2, status["game_info"]["id"], type)
        client1[:game] = game
        client2[:game] = game

        game.start

        game.on_game_end = lambda do |winner|
          if winner == false
            if websocket_open(client1[:ws])
              client1[:ws].close
              client2[:ws].close
            end
          else
            winner = JSON.parse(winner)
            @logger.log('Pong', "winner #{winner['winner']}")
            if winner['winner']
              handle_result(client1, client2, tournament_id)
            else
              handle_result(client2, client1, tournament_id)
            end
          end
        end

        client1[:ws].onmessage do |message|
          game.receive_message(client1, message)
        end

        client2[:ws].onmessage do |message|
          game.receive_message(client2, message)
        end
        
      else
        @logger.log('Pong', "Error creating game")
      end
    end
  end

  def handle_result(winner, looser, tournament_id)
    if websocket_open(looser[:ws])
      looser[:ws].send({status: "Lose"}.to_json)
      looser[:ws].close
    end
    @tournaments[tournament_id][:players].delete(looser[:player]["id"])
    winner[:opponent] = nil
    winner[:game] = nil
    if websocket_open(winner[:ws])
      winner[:ws].send({status: "Win"}.to_json)
    end
    build_tournament(tournament_id)
  end

  def build_tournament(tournament_id)
    @logger.log('Pong', "Building tournament")
    players = @tournaments[tournament_id][:players]
    if players.length == 1
      winner_id, winner_data = players.first
      if websocket_open(winner_data[:ws])
        winner_data[:ws].send({ status: "Win" }.to_json)
        winner_data[:ws].close
      end
      @pong_api.end_tournament('http://ruby_pong_api:4571/api/tournament', tournament_id, winner_id) do |status|
        @logger.log('Pong', "Tournament ended")
        @tournaments.delete(tournament_id)
      end
      return
    end
    players.each do |player_id, player_data|
      next unless player_data[:opponent].nil?
      opponent_id, opponent_data = players.find do |_id, data|
        data[:opponent].nil? && _id != player_id
      end
      if opponent_data
        player_data[:opponent] = opponent_data
        opponent_data[:opponent] = player_data
        create_game(player_data, opponent_data, tournament_id, 3)
      else
        tz = TZInfo::Timezone.get('Europe/Paris')
        time_in_paris = Time.now
        if websocket_open(player_data[:ws])
          player_data[:ws].send({
            status: "Waiting",
            time_end: (time_in_paris + 61 * 60).strftime("%Y-%m-%d %H:%M:%S")
          }.to_json)
        end
      end
    end
  end
  

  def start_tournament(tournament_id, jwt)
    @pong_api.start_tournament('http://ruby_pong_api:4571/api/tournament/start', tournament_id, jwt) do |status|
      if status
        @tournaments[tournament_id][:tournament]["tournament"]["status"] = "started"
        @tournaments[tournament_id][:players].each_value do |player|
          if websocket_open(player[:ws])
            player[:ws].send({ status: "Started" }.to_json)
          end
        end
        build_tournament(tournament_id)
      else
        @logger.log('Pong', "Error starting tournament")
      end
    end
  end

  def tournament(client, tournament_id, cookie)
    if @tournaments[tournament_id].nil?
      @pong_api.get_tournament('http://ruby_pong_api:4571/api/tournament', tournament_id) do |status|
        if status.nil?
          if websocket_open(client)
            client.send({ error: "Invalid tournament" }.to_json)
            client.close
          end
        else
          @tournaments[tournament_id] = { tournament: status, players: {}, start_timer: nil }
          @user_api.user_logged(cookie['access_token']) do |logged|
            @user_api.get_user_info("http://ruby_user_management:4567/api/user/#{logged["user_id"]}") do |player|
              if player.nil?
                if websocket_open(client)
                  client.send({ error: "Invalid player" }.to_json)
                  client.close
                end
                @logger.log('Pong', "Error getting player info")
                next
              end
              player[:opponent] = nil
              @tournaments[tournament_id][:players][player["id"]] = { player: player, ws: client }
              end_time = Time.strptime(@tournaments[tournament_id][:tournament]["tournament"]["start_at"], "%Y-%m-%d %H:%M:%S")
              tz = TZInfo::Timezone.get('Europe/Paris')
              @tournaments[tournament_id][:start_timer] = end_time
              current_time = Time.now
              delay = [end_time - current_time, 0].max
              client.send({ status: "Waiting", time_end: @tournaments[tournament_id][:start_timer] }.to_json)
              if delay > 0
                EM.add_timer(delay) do
                  if @tournaments[tournament_id][:players].length >= 2
                    start_tournament(tournament_id, cookie['access_token'])
                  else
                    @pong_api.end_tournament('http://ruby_pong_api:4571/api/tournament', tournament_id, nil) do |status|
                      if websocket_open(@tournaments[tournament_id][:players][player["id"]][:ws])
                        @tournaments[tournament_id][:players][player["id"]][:ws].send({ end: "end" }.to_json)
                        @tournaments[tournament_id][:players][player["id"]][:ws].close
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    elsif
      @user_api.user_logged(cookie['access_token']) do |logged|
        @user_api.get_user_info("http://ruby_user_management:4567/api/user/#{logged["user_id"]}") do |player|
          if player.nil?
            if websocket_open(client)
              client.send({ error: "Invalid player" }.to_json)
              client.close
            end
            @logger.log('Pong', "Error getting player info")
            next
          end
          if @tournaments[tournament_id][:tournament]["tournament"]["status"] == "started"
            if @tournaments[tournament_id][:players][player["id"]]
              @tournaments[tournament_id][:players][player["id"]][:ws] = client
              if @tournaments[tournament_id][:players][player["id"]][:game]
                @logger.log('Pong', "Reconnecting player")
                @tournaments[tournament_id][:players][player["id"]][:game].reconnection(@tournaments[tournament_id][:players][player["id"]])
                next
              end
              if websocket_open(client)
                client.send({
                  status: "Waiting",
                  time_end: (Time.now + 1 * 60).strftime("%Y-%m-%d %H:%M:%S")
                }.to_json)
              end
              next
            end
            if websocket_open(client)
              client.send({ error: "Tournament already started" }.to_json)
              client.close
            end
          else
            if @tournaments[tournament_id][:players][player["id"]].nil?
              @tournaments[tournament_id][:players][player["id"]] = { player: player, ws: client }
            else
              @tournaments[tournament_id][:players][player["id"]][:ws] = client
            end
            if websocket_open(client)
              client.send({ status: "Waiting", time_end: @tournaments[tournament_id][:start_timer] }.to_json)
            end
          end
        end
      end
    end
  end  
end