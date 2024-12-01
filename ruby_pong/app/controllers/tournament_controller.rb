require_relative '../log/custom_logger'
require_relative '../services/tournament'

class TournamentController
  def initialize(logger = Logger.new, tournament = Tournament.new)
    @logger = logger
    @tournament = tournament
  end

  def route_request(client, event)
    path = event.path
    headers = event.headers
    user_page_match = path.match(%r{^/pongsocket/tournament/(\d+)$})
    if user_page_match
      tournament(client, user_page_match[1], headers)
    else
      return 1
    end
  end

  def tournament(client, tournament_id, headers)
    @logger.log("tournament", "tournament")
    cookies = headers['Cookie'].split('; ').map { |c| c.split('=', 2) }.to_h
    @tournament.tournament(client, tournament_id, cookies)
  end

end