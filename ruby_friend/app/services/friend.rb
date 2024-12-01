require_relative '../log/custom_logger'
require_relative 'external/user_api'

class Friend
  def initialize(logger = Logger.new, user_api = UserApi.new)
    @logger = logger
    @user_api = user_api
    @userlogged = {}
  end

  def add_friend(data, user_id)
    if @userlogged[data['friend_id']]
      @userlogged[data['friend_id']][:ws].send({
        type: 'friend_request',
        username: @userlogged[user_id][:username],
        friendship_id: data['friendship_id']
      }.to_json)
    end
  end

  def send_message(data, user_id)
    friend_id = data['friend_id']
    if !@userlogged[user_id][:friends].include?(friend_id)
      @userlogged[user_id][:ws].send({
        type: 'error',
        message: "Cannot send message: the user is not your friend."
      }.to_json)
      return
    end
    if !@userlogged[friend_id]
      @userlogged[user_id][:ws].send({
        type: 'error',
        message: "Cannot send message: the user is not online."
      }.to_json)
      return
    end
    @userlogged[friend_id][:ws].send({
      type: 'message',
      sender: @userlogged[user_id][:username],
      message: data['message']
    }.to_json)
  end

  def new_friend(data, user_id)
    if @userlogged[data['friend_id']]
      @userlogged[data['friend_id']][:ws].send({
        type: 'new_friend',
        friend_id: user_id,
        friendship_id: data['friendship_id'],
        status: data['status']
      }.to_json)
      if @userlogged[user_id]
        @userlogged[user_id][:friends].push(data['friend_id'])
        @userlogged[data['friend_id']][:friends].push(user_id)
        @userlogged[user_id][:ws].send({
          type: 'friend_connected',
          friend: data['friend_id']
        }.to_json)
        @userlogged[data['friend_id']][:ws].send({
          type: 'friend_connected',
          friend: user_id
        }.to_json)
      end
    end
  end

  def friend(client, cookie)
    jwt = cookie['access_token']
    @user_api.user_logged(jwt) do |user|
      if user
        user_id = user["user_id"]
        @userlogged[user_id] = { ws: client, friends: [], username: user["username"] }
        @user_api.get_user_friends(user_id) do |friends|
          if friends
            friend_ids = friends
              .select { |f| f["status"] == "accepted" }
              .map { |f| f["requester_id"] == user_id ? f["receiver_id"] : f["requester_id"] }
            if @userlogged[user_id].nil?
              @userlogged[user_id] = { ws: client, friends: friend_ids, username: user["username"] }
            else
              @userlogged[user_id][:friends] = friend_ids
            end
            friend_ids.each do |friend_id|
              if @userlogged[friend_id]
                @userlogged[friend_id][:ws].send({
                  type: 'friend_connected',
                  friend: user_id
                }.to_json)
                client.send({
                  type: 'friend_connected',
                  friend: friend_id
                }.to_json)
              end
            end
          end
        end
        client.onclose do
          if @userlogged[user_id][:friends].nil?
            @userlogged[user_id][:friends] = []
          end
          @userlogged[user_id][:friends].each do |friend_id|
            if @userlogged[friend_id]
              @userlogged[friend_id][:ws].send({
                type: 'friend_disconnected',
                friend: user_id
              }.to_json)
            end
          end
          @userlogged.delete(user_id)
        end

        client.onmessage do |message|
          begin
            data = JSON.parse(message)
            @user_api.user_in_friendship(data['friendship_id'], data['friend_id'], user_id) do |friendship|
              if !friendship
                client.send({ error: 'Unauthorized' }.to_json)
              else
                case data['type']
                when "add_friend"
                  add_friend(data, user_id)
                when "new_friend"
                  new_friend(data, user_id)
                when "message"
                  send_message(data, user_id)
                end
              end
            end
          rescue JSON::ParserError => e
            @logger.log('Friend', "Invalid JSON: #{message}")
          end
        end

      else
        @logger.log('Friend', "Unauthorized user")
        client.send({ error: 'Unauthorized' }.to_json)
        client.close
      end
    end
  end
end
