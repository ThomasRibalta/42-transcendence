require_relative '../config/database'
require_relative '../log/custom_logger'

class FriendRepository

  def initialize(logger = CustomLogger.new)
    @logger = logger
  end

  def friend_exists(user_id, friend_id)
    @logger.log("FriendRepository", "Checking if friendship exists with user_id: #{user_id} and friend_id: #{friend_id}")
    Database.get_one_element_from_table('_friendship', {}, {requester_id: user_id, receiver_id: friend_id}).any?
  end

  def add_friend(user_id, friend_id)
    @logger.log("FriendRepository", "Adding friend with user_id: #{user_id} and friend_id: #{friend_id}")
    Database.insert_into_table('_friendship', {requester_id: user_id, receiver_id: friend_id})
  end

  def get_friends(user_id)
    @logger.log("FriendRepository", "Getting friends for user_id: #{user_id}")
    Database.get_friendship_plus_information(user_id)
  end

  def get_friendship(friendship_id)
    @logger.log("FriendRepository", "Getting friendship with friendship_id: #{friendship_id}")
    Database.get_one_element_from_table('_friendship', {id: friendship_id}).first
  end

  def update_friendship(friendship_id, status)
    @logger.log("FriendRepository", "Updating friendship with friendship_id: #{friendship_id} and status: #{status}")
    Database.update_table('_friendship', {status: status}, {} , {id: friendship_id})
    @logger.log("FriendRepository", "Friendship updated successfully")
  end

  def delete_friendship(friendship_id)
    @logger.log("FriendRepository", "Deleting friendship with friendship_id: #{friendship_id}")
    Database.update_table('_friendship', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {}, {id: friendship_id})
    @logger.log("FriendRepository", "Friendship deleted successfully")
  end

end