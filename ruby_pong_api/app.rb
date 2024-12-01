require 'socket'
require_relative 'app/controllers/pong_controller'
require_relative 'app/controllers/tournament_controller'
require_relative 'app/config/request_helper'
require_relative 'app/log/custom_logger'

server = TCPServer.new('0.0.0.0', 4571)
pong_controller = PongController.new
tournament_controller = TournamentController.new

loop do
  begin
    client = server.accept
    method, path, headers, cookies, body = RequestHelper.parse_request(client)
    
    status_pong = pong_controller.route_request(client, method, path, body, headers, cookies)
    status_tournament = tournament_controller.route_request(client, method, path, body, headers, cookies)

    if status_pong == 1 && status_tournament == 1
      RequestHelper.not_found(client)
    end
  rescue Errno::EPIPE => e
    Logger.new.log("test", "Erreur : Broken pipe - #{e.message}")
  rescue Errno::ECONNRESET => e
    Logger.new.log("test", "Erreur : Connection reset - #{e.message}")
  ensure
    client.close if client
  end
end
