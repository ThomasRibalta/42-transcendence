require 'webrick'
require 'erb'
require 'ostruct'
require 'json'
require 'net/http'
require_relative 'app/log/custom_logger'

mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
mime_types['js'] = 'application/javascript'
mime_types['mjs'] = 'application/javascript'
server = WEBrick::HTTPServer.new(:Port => 4568, :MimeTypes => mime_types)
logger = Logger.new

def game_result(game, user_id)
  is_player_1 = game["player_1_id"].to_i == user_id.to_i
  user_score = is_player_1 ? game["player_1_score"].to_i : game["player_2_score"].to_i
  opponent_score = is_player_1 ? game["player_2_score"].to_i : game["player_1_score"].to_i
  rank_points = game["rank_points"] || 0

  result_text = user_score > opponent_score ? "Victory" : "Defeat"
  score_text = "Score: #{user_score} - #{opponent_score}"
  rank_text = rank_points != 0 ? "(Rank points: #{result_text == 'Victory' ?  '+' : '-'}#{rank_points})" : ""

  "<span class='badge bg-#{result_text == 'Victory' ? 'success' : 'danger'} me-2'>#{result_text}</span> " \
  "<span class='text-muted'>#{score_text}</span> " \
  "<small class='text-secondary ms-2'>#{rank_text}</small>" \
  "#{game_tournament(game)}"
end

def game_tournament(game)
  game["type"].to_i == 3 ? "<span class='badge bg-primary'>Tournament</span>" : ""
end


def user_logged(jwt, logger)
	uri = URI('http://ruby_user_management:4567/api/auth/verify-token-user')
	req = Net::HTTP::Get.new(uri)
	req['Cookie'] = "access_token=#{jwt}"
	http = Net::HTTP.new(uri.host, uri.port)
	res = http.start do |http|
		http.request(req)
	end
	logger.log('App', "Response from /api/auth/verify-token-user: #{res.body}")
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
		logger.log('App', "User logged #{JSON.parse(res.body)}.")
		JSON.parse(res.body)
  else
		logger.log('App', "Failed to verify token: #{res.code} #{res.message}")
    return false
  end
end

def get_user_info(api_url)
  uri = URI(api_url)
	req = Net::HTTP::Get.new(uri)
	http = Net::HTTP.new(uri.host, uri.port)
	res = http.start do |http|
		http.request(req)
	end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)["user"].first
  else
    nil
  end
end

def get_users_paginated(page)
  uri = URI("http://ruby_user_management:4567/api/users/#{page}")
  req = Net::HTTP::Get.new(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  res = http.start do |http|
    http.request(req)
  end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  else
    nil
  end
end

def get_user_stats(user_id)
  uri = URI("http://ruby_pong_api:4571/api/pong/player/stats/#{user_id}")
  req = Net::HTTP::Get.new(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  res = http.start do |http|
    http.request(req)
  end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)["stats"]
  else
    nil
  end
end

def get_friends(user_id)
  uri = URI("http://ruby_user_management:4567/api/friends/#{user_id}")
  req = Net::HTTP::Get.new(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  res = http.start do |http|
    http.request(req)
  end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  else
    nil
  end
end

def get_tournaments()
  uri = URI("http://ruby_pong_api:4571/api/tournaments/")
  req = Net::HTTP::Get.new(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  res = http.start do |http|
    http.request(req)
  end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  else
    nil
  end
end

def get_tournament(tournament_id)
  uri = URI("http://ruby_pong_api:4571/api/tournament/#{tournament_id}")
  req = Net::HTTP::Get.new(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  res = http.start do |http|
    http.request(req)
  end
  res.finish if res.respond_to?(:finish)
  if res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  else
    nil
  end
end

def get_access_token(req)
	access_token = req.cookies.find { |cookie| cookie.name == 'access_token' }
	if access_token
		access_token = access_token.value
	else
		access_token = nil
	end
	access_token
end

def generate_navigation
  ERB.new(File.read("app/view/layouts/nav.erb")).result(binding)
end

def generate_response(req, res, logger)
  if req['X-Requested-With'] == 'XMLHttpRequest'
    json = { body: @pRes }
    logger.log('App', "Request IsLogged: #{req['IsLogged']}")
    if (@user_logged && req['IsLogged'] == 'false') || (!@user_logged && req['IsLogged'] == 'true')
      json[:nav] = @nav
    end
    res.content_type = "application/json"
    res.body = json.to_json
  else
    template = ERB.new(File.read("app/view/index.erb"))
    res.body = template.result(binding)
    res.content_type = "text/html"
  end
	@user_logged = nil
	@nav = nil
	@pRes = nil
end

def handle_route(req, res, logger, template_path)
  access_token = get_access_token(req)
  logger.log('App', "Request received with access token: #{access_token}")
  
  @user_logged = user_logged(access_token, logger)
  logger.log("debug", @user_logged)
  @friends = {}
  if @user_logged
    @friends = get_friends(@user_logged["user_id"])
  end
  @nav = generate_navigation
  
  page = ERB.new(File.read(template_path))
  @pRes = page.result(binding)

  generate_response(req, res, logger)
end

server.mount_proc '/' do |req, res|
	handle_route(req, res, logger, "app/view/default.erb")
end

server.mount_proc '/pong' do |req, res|
	handle_route(req, res, logger, "app/view/localpong.erb")
end

server.mount_proc '/register' do |req, res|
	handle_route(req, res, logger, "app/view/register.erb")
end

server.mount_proc '/login' do |req, res|
	handle_route(req, res, logger, "app/view/login.erb")
end

server.mount_proc '/validate-code' do |req, res|
	handle_route(req, res, logger, "app/view/validate-code.erb")
end

server.mount_proc '/callback-tmp' do |req, res|
	handle_route(req, res, logger, "app/view/callback-tmp.erb")
end

server.mount_proc '/pongserv' do |req, res|
  handle_route(req, res, logger, "app/view/pongserv.erb")
end

server.mount_proc '/3dgame' do |req, res|
  handle_route(req, res, logger, "app/view/threejs.erb")
end

server.mount_proc '/pongserv-ranked' do |req, res|
  handle_route(req, res, logger, "app/view/pongserv-ranked.erb")
end

server.mount_proc '/profile' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation

  if @user_logged
    user_info = get_user_info("http://ruby_user_management:4567/api/user/#{@user_logged["user_id"]}")
    if user_info
      @stats = get_user_stats(user_info["id"])
      logger.log('App', "Stats: #{@stats}")
      @user = user_info
      page = ERB.new(File.read("app/view/profile.erb"))
      @pRes = page.result(binding)
    else
      res.status = 500
      @pRes = "Erreur lors de la récupération des informations utilisateur."
    end
  else
    res.status = 401
    @pRes = "Utilisateur non authentifié."
  end

  generate_response(req, res, logger)
end

server.mount_proc '/rgpd' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation

  if @user_logged
    user_info = get_user_info("http://ruby_user_management:4567/api/user/#{@user_logged["user_id"]}")
    if user_info
      @stats = get_user_stats(user_info["id"])
      logger.log('App', "Stats: #{@stats}")
      @user = user_info
      page = ERB.new(File.read("app/view/rgpd.erb"))
      @pRes = page.result(binding)
    else
      res.status = 500
      @pRes = "Erreur lors de la récupération des informations utilisateur."
    end
  else
    res.status = 401
    @pRes = "Utilisateur non authentifié."
  end

  generate_response(req, res, logger)
end

server.mount_proc '/edit-profile' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation

  if @user_logged
    user_info = get_user_info("http://ruby_user_management:4567/api/user/#{@user_logged["user_id"]}")
    if user_info
      @user_info = user_info
      page = ERB.new(File.read("app/view/edit-profile.erb"))
      @pRes = page.result(binding)
    else
      res.status = 500
      @pRes = "Erreur lors de la récupération des informations utilisateur."
    end
  else
    res.status = 401
    @pRes = "Utilisateur non authentifié."
  end

  generate_response(req, res, logger)
end

server.mount_proc '/ranking' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @current_page = req.path.match(/\/ranking\/(\d+)/)[1].to_i rescue 1
  users = get_users_paginated(@current_page)
  @nav = generate_navigation
  if users
    @users = users["users"]
    @nPages = users["nPages"].to_i + 1
    page = ERB.new(File.read("app/view/ranking.erb"))
    @pRes = page.result(binding)
  else
    res.status = 500
    @pRes = "Erreur lors de la récupération des utilisateurs."
  end

  generate_response(req, res, logger)
end

server.mount_proc '/tournaments' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation
  tournaments = get_tournaments();
  if tournaments
    @tournaments = tournaments["tournaments"]
  else
    @tournaments = []
  end
  page = ERB.new(File.read("app/view/tournaments.erb"))
  @pRes = page.result(binding)
  generate_response(req, res, logger)
end

server.mount_proc '/create-tournament' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation
  page = ERB.new(File.read("app/view/create-tournament.erb"))
  @pRes = page.result(binding)
  generate_response(req, res, logger)
end

server.mount_proc '/tournament/' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation
  tournament_id = req.path.match(/\/tournament\/(\d+)/)[1].to_i rescue nil
  if tournament_id
    tournament = get_tournament(tournament_id)
    logger.log('App', "Tournament: #{tournament}")
    if tournament
      @tournament_id = tournament["tournament"]["id"]
      page = ERB.new(File.read("app/view/tournament.erb"))
      @pRes = page.result(binding)
    else
      res.status = 404
      @pRes = "Tournoi introuvable."
    end
  else
    res.status = 400
    @pRes = "Identifiant de tournoi invalide."
  end
  generate_response(req, res, logger)
end

server.mount_proc '/rgpd' do |req, res|
  @user_logged = user_logged(get_access_token(req), logger)
  @nav = generate_navigation

  if @user_logged
    user_info = get_user_info("http://ruby_user_management:4567/api/user/#{@user_logged["user_id"]}")
    if user_info
      @stats = get_user_stats(user_info["id"])
      logger.log('App', "Stats: #{@stats}")
      @user = user_info
      page = ERB.new(File.read("app/view/rgpd.erb"))
      @pRes = page.result(binding)
    else
      res.status = 500
      @pRes = "Erreur lors de la récupération des informations utilisateur."
    end
  else
    res.status = 401
    @pRes = "Utilisateur non authentifié."
  end

  generate_response(req, res, logger)
end

server.mount '/static', WEBrick::HTTPServlet::FileHandler, './static'
server.mount '/assets', WEBrick::HTTPServlet::FileHandler, './assets'

trap 'INT' do server.shutdown end
server.start
