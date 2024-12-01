require_relative '../repository/friend_repository'
require_relative '../repository/user_repository'
require_relative '../log/custom_logger'
require 'securerandom'
require 'uri'
require 'net/http'
require 'json'

class FriendManager

  def initialize(friend_repository = FriendRepository.new, user_repository = UserRepository.new, logger = CustomLogger.new)
    @friend_repository = friend_repository
    @logger = logger
    @user_repository = user_repository
  end

  def add_friend(user_id, body)
    if body['friend_id'].nil? || body['friend_id'].to_i < 1
      @logger.log('FriendManager', "Invalid friend ID: #{body['friend_id']}")
      return {code: 400, error: 'Invalid friend ID' }
    end
    friend_id = body['friend_id']
    if user_id == friend_id
      @logger.log('FriendManager', "Cannot add yourself as a friend")
      return {code: 400, error: 'Cannot add yourself as a friend' }
    end
    friend = @user_repository.get_user_by_id(friend_id)[0]
    if friend.nil?
      @logger.log('FriendManager', "Friend does not exist")
      return {code: 400, error: 'Friend does not exist' }
    end
    if @friend_repository.friend_exists(user_id, friend_id)
      @logger.log('FriendManager', "Friendship already exists")
      return {code: 400, error: 'Friendship already exists' }
    end
    friendship = @friend_repository.add_friend(user_id, friend_id)
    user = @user_repository.get_user_by_id(user_id)[0]
    @logger.log('FriendManager', "Friend added")
    return {code: 200, success: 'Friend added', friendship_id: friendship["id"],
      friend_name: friend["username"], friend_id: friend["id"] }
  end

  def get_friends(user_id)
    friends = @friend_repository.get_friends(user_id)
    return friends
  end

  def update_friends(user_id, friendship_id, body)
    if body["status"].nil?
      @logger.log('FriendManager', "Invalid status: #{body["status"]}")
      return {code: 400, error: 'Invalid status' }
    end
    status = body["status"]
    friendship = @friend_repository.get_friendship(friendship_id)
    if friendship.nil?
      @logger.log('FriendManager', "Friendship does not exist")
      return {code: 400, error: 'Friendship does not exist' }
    end
    if friendship["requester_id"].to_i != user_id.to_i && friendship["receiver_id"].to_i != user_id.to_i
      @logger.log('FriendManager', "User is not part of the friendship")
      return {code: 400, error: 'User is not part of the friendship' }
    end
    if friendship["requester_id"].to_i == user_id.to_i
      @logger.log('FriendManager', "Sender cannot accept friendship")
      return {code: 400, error: 'Sender cannot accept friendship' }
    end
    if status != "accepted"
      @logger.log('FriendManager', "Friendship is not accepted")
      @friend_repository.delete_friendship(friendship_id)
      return {code: 200, success: 'Friendship is refused', friendship: friendship }  
    end
    @friend_repository.update_friendship(friendship_id, status)
    @logger.log('FriendManager', "Friendship updated")
    return {code: 200, success: 'Friendship updated', friendship: friendship }
  end

  def delete_friends(user_id, friendship_id)
    friendship = @friend_repository.get_friendship(friendship_id)
    if friendship.nil?
      @logger.log('FriendManager', "Friendship does not exist")
      return {code: 400, error: 'Friendship does not exist' }
    end
    if friendship["requester_id"].to_i != user_id.to_i && friendship["receiver_id"].to_i != user_id.to_i
      @logger.log('FriendManager', "User is not part of the friendship")
      return {code: 400, error: 'User is not part of the friendship' }
    end
    @friend_repository.delete_friendship(friendship_id)
    @logger.log('FriendManager', "Friendship deleted")
    return {code: 200, success: 'Friendship deleted' }
  end

  def get_friend(user_id, friendship_id, friend_id)
    @logger.log('FriendManager', "Checking friendship with user_id: #{user_id}, friendship_id: #{friendship_id}, friend_id: #{friend_id}")
    friendship = @friend_repository.get_friendship(friendship_id)
    if friendship.nil?
      @logger.log('FriendManager', "Friendship does not exist")
      return {code: 400, error: 'Friendship does not exist' }
    end
    if (friendship["requester_id"].to_i != friend_id.to_i && friendship["receiver_id"].to_i != user_id.to_i) &&
      (friendship["requester_id"].to_i != user_id.to_i && friendship["receiver_id"].to_i != friend_id.to_i)
      @logger.log('FriendManager', "User is not part of the friendship")
      return {code: 400, error: 'User is not part of the friendship' }
    end
    @logger.log('FriendManager', "Friendship found")
    return {code: 200, success: 'Friendship found' }
  end
end