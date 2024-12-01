require_relative '../repository/tournament_repository'
require 'tzinfo'

class TournamentManager

  def initialize(logger = Logger.new, tournament_repository = TournamentRepository.new, pong_repository = PongRepository.new)
    @logger = logger
    @tournament_repository = tournament_repository
    @pong_repository = pong_repository
  end

  def create_tournament(body, user_id)
    @logger.log('TournamentManager', 'Creating tournament')
    if body['name'].nil? || body['name'].empty? || body['name'].length > 50 || body['name'].length < 3
      return { code: 400, error: 'Invalid tournament name' }
    end
    tz = TZInfo::Timezone.get('Europe/Paris')
    france_time = Time.now
    start_time = (france_time + 1 * 60).strftime("%Y-%m-%d %H:%M:%S")
    updated_time = france_time.strftime("%Y-%m-%d %H:%M:%S")

    tournament_info = {
      name: body['name'],
      host_id: user_id,
      start_at: start_time,
      updated_at: updated_time
    }

    tournament = @tournament_repository.create_tournament(tournament_info)
    return { code: 200, success: "Succesfully created", tournament: tournament }
  end

  def get_tournament(tournament_id)
    @logger.log('TournamentManager', "Getting tournament #{tournament_id}")
    tournament = @tournament_repository.get_tournament(tournament_id)
    if tournament.nil?
      return { code: 404, error: 'Tournament not found' }
    end
    { code: 200, tournament: tournament }
  end

  def get_tournaments()
    @logger.log('TournamentManager', 'Getting tournaments')
    tournaments = @tournament_repository.get_tournaments()
    return { code: 200, tournaments: tournaments }
  end

  def delete_tournament(tournament_id, body)
    @logger.log('TournamentManager', "Deleting tournament #{tournament_id}")
    if (body['id_winner'].nil? || body['id_winner'].empty?)
      @tournament_repository.delete_tournament(tournament_id)
      return { code: 200, success: 'Tournament' }
    end
    game_history_player_1 = @pong_repository.get_game_history(body['id_winner']);
    if game_history_player_1.nil?
      return { code: 404, error: 'Player not found' }
    end
    history_updated = {
      nb_win_tournament: game_history_player_1["nb_win_tournament"].to_i + 1 
    }
    @pong_repository.save_game_history(history_updated, body['id_winner'])
    @tournament_repository.delete_tournament(tournament_id)
    return { code: 200, success: 'Tournament deleted' }
  end

end