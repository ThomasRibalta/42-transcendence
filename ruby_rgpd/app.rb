require 'socket'
require_relative './app/config/request_helper'
require_relative './app/controller/rgpd_controller'

server = TCPServer.new('0.0.0.0', 4570)
puts "RGPD Service running on port 4570"

rgpd_controller = RGPDController.new

loop do
  begin
    client = server.accept
    method, path, headers, _cookies, body = RequestHelper.parse_request(client)
    rgpd_controller.route_request(client, method, path, headers, body)
  rescue StandardError => e
    puts "Error: #{e.message}"
    RequestHelper.respond(client, 500, { error: "Internal server error" })
  ensure
    client.close if client
  end
end
