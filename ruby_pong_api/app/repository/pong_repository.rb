require_relative '../config/database'
require_relative '../log/custom_logger'

class PongRepository

  def initialize(logger = Logger.new)
    @logger = logger
  end

  def create_game_history(game_info)
    Database.insert_into_table('_pongHistory', game_info)
  end

  def create_game(game_info)
    Database.insert_into_table('_pong', game_info)
  end

  def get_game_one_user(user_id)
    game = Database.get_one_element_from_table('_pong', { player_1_id: user_id, player_2_id: user_id }, {state: 3})
    if game.length > 0
      game[0]
    else
      nil
    end
  end


  def get_game_history(user_id)
    history = Database.get_one_element_from_table('_pongHistory', {}, { user_id: user_id })
    if history.length > 0
      history[0]
    else
      nil
    end
  end

  def save_game(game_update, game_id)
    Database.update_table('_pong', game_update, {}, { id: game_id })
  end

  def get_game(player_id)
    game = Database.get_one_element_from_table('_pong', {}, { player_1_id: player_id })
    if game.length > 0
      game[0]
    else
      nil
    end
  end

  def save_game_history(game_info, user_id)
    Database.update_table('_pongHistory', game_info, {}, { user_id: user_id })
  end

  def get_user_stats(user_id)
    stats = Database.get_user_stats_and_games(user_id)
    if stats
      stats
    else
      nil
    end
  end
end