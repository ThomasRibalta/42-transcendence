require_relative '../config/database'
require_relative '../log/custom_logger'

class UserRepository

  def initialize(logger = CustomLogger.new)
    @logger = logger
  end

  def register_complement_info(history)
    @logger.log('AuthRepository', "Registering complement info")
    Database.insert_into_table('_pongHistory', history)
    @logger.log('AuthRepository', "Complement info for user registered")
  end

  def register_user_42(user_info)
    @logger.log('AuthRepository', "Registering user42 with email #{user_info[:email]}")
    Database.insert_into_table('_user', user_info)
    @logger.log('AuthRepository', "User42 with email #{user_info[:email]} registered")
  end

  def update_user(user_info, user_id)
    @logger.log('AuthRepository', "Updating user with email #{user_info[:email]}")
    Database.update_table('_user', user_info, {}, {id: user_id})
    @logger.log('AuthRepository', "User with email #{user_info[:email]} updated")
  end

  def get_user_by_email(email)
    Database.get_one_element_from_table('_user', {email: email })
  end

  def get_user_by_id(id)
    Database.get_one_element_from_table('_user', {id: id })
  end

  def register(user_info)
    @logger.log('AuthRepository', "Registering user with email #{user_info[:email]}")
    Database.insert_into_table('_user', user_info)
    @logger.log('AuthRepository', "User with email #{user_info[:email]} registered")
  end

  def get_paginated_users(page)
    Database.get_paginated_element_from_table(page, 10)
  end

  def get_all_users()
    Database.get_all_from_table('_user')
  end

  def delete_user(user_id)
    @logger.log('AuthRepository', "Deleting user : #{user_id}")
    Database.update_table('_user', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {}, {id: user_id})
    Database.update_table('_friendship', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {requester_id: user_id, receiver_id: user_id}, {})
    Database.update_table('_emailActivation', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {}, {user_id: user_id})
    Database.update_table('_pong', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {player_1_id: user_id, player_2_id: user_id}, {})
    Database.update_table('_pongHistory', {deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S")}, {}, {user_id: user_id})
    @logger.log('AuthRepository', "User deleted successfully")
  end

end