require 'em-websocket'
require 'eventmachine'
require_relative 'app/log/custom_logger'
require_relative 'app/controllers/pong_controller'
require_relative 'app/controllers/tournament_controller'

class AppServer
  def initialize(logger = Logger.new, pongController = PongController.new, tournamentController = TournamentController.new)
    @logger = logger
    @pongController = pongController
    @tournamentController = tournamentController
  end

  def start
    EM.run do
      @logger.log('APP', "Starting server on localhost:4569")
      EM::WebSocket.run(host: "0.0.0.0", port: 4569) do |ws|
        ws.onopen do |event|
          pong = @pongController.route_request(ws, event)
          tournament = @tournamentController.route_request(ws, event)
          if pong == 1 && tournament == 1
            ws.send({error:"Invalid path"}.to_json)
            ws.close
          end
        end
      end
    end
  end
end

AppServer.new.start