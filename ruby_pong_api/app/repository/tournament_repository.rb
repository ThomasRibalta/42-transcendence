require_relative '../config/database'
require_relative '../log/custom_logger'

class TournamentRepository

  def initialize(logger = Logger.new)
    @logger = logger
  end

  def create_tournament(tournament_info)
    Database.insert_into_table('_tournament', tournament_info)
  end

  def get_tournament(tournament_id)
    tournament = Database.get_one_element_from_table('_tournament', {}, { id: tournament_id })
    if tournament.length > 0
      tournament[0]
    else
      nil
    end
  end

  def get_tournaments()
    Database.get_all_from_table('_tournament')
  end

  def update_tournament(tournament_info, tournament_id)
    Database.update_table('_tournament', tournament_info, {}, { id: tournament_id })
  end

  def delete_tournament(tournament_id)
    Database.update_table('_tournament', { deleted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S") }, {}, { id: tournament_id })
  end

end