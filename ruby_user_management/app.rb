require 'socket'
require_relative 'app/controllers/auth_controller'
require_relative 'app/controllers/token_controller'
require_relative 'app/controllers/user_controller'
require_relative 'app/controllers/friend_controller'
require_relative 'app/config/request_helper'
require_relative 'app/log/custom_logger'

server = TCPServer.new('0.0.0.0', 4567)
puts "Ruby User Management server running on port 4567"

authController = AuthController.new
tokenController = TokenController.new
userController = UserController.new
friendController = FriendController.new
logger = CustomLogger.new


loop do
  begin
    client = server.accept
    method, path, headers, cookies, body = RequestHelper.parse_request(client)

    foundAuth = authController.route_request(client, method, path, body, headers, cookies)
    foundToken = tokenController.route_request(client, method, path, body, headers, cookies)
    foundUser = userController.route_request(client, method, path, body, headers, cookies)
    foundFriend = friendController.route_request(client, method, path, body, headers, cookies)

    if foundUser == 1 && foundToken == 1 && foundAuth == 1 && foundFriend == 1
      RequestHelper.not_found(client)
    end
  rescue Errno::EPIPE => e
    logger.log("test", "Erreur : Broken pipe - #{e.message}")
  ensure
    client.close if client
  end
end
