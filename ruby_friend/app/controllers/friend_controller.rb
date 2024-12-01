require_relative '../log/custom_logger'
require_relative '../services/friend'

class FriendController
  def initialize(logger = Logger.new, friend = Friend.new)
    @logger = logger
    @friend = friend
  end

  def route_request(client, event)
    path = event.path
    headers = event.headers
    case path
    when '/friendsocket/'
      @logger.log('PongController', "Received request to /friendsocket/")
      friend(client, headers)
    else
      client.send('Invalid path')
      client.close
    end
  end

  def friend(client, headers)
    cookie = headers['Cookie'].split('; ').map { |c| c.split('=', 2) }.to_h
    @friend.friend(client, cookie)
  end

end