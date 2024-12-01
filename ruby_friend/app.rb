require 'em-websocket'
require 'eventmachine'
require_relative 'app/log/custom_logger'
require_relative 'app/controllers/friend_controller'

class AppServer
  def initialize(logger = Logger.new, friendController = FriendController.new)
    @logger = logger
    @friendController = friendController
  end

  def start
    EM.run do
      @logger.log('APP', "Starting server on localhost:4560")
      EM::WebSocket.run(host: "0.0.0.0", port: 4560) do |ws|
        ws.onopen do |event|
          @friendController.route_request(ws, event)
        end
      end
    end
  end
end

AppServer.new.start