require 'json'
require 'em-http-request'
require_relative '../../log/custom_logger'

class UserApi

	def initialize(logger = Logger.new)
		@logger = logger
	end

  def get_user_info(api_url, &callback)
    http = EM::HttpRequest.new(api_url).get()
	@logger.log("UserAPI", "get user info start")
    http.callback do
      if http.response_header.status == 200
        callback.call(JSON.parse(http.response)["user"][0]) if callback
		@logger.log("UserAPI", "get user info good response")
		else
        callback.call(nil) if callback
      end
    end
    
    http.errback do
      callback.call(nil) if callback
    end
	@logger.log("UserAPI", "get user info end")
end

  def user_logged(jwt, &callback)
	uri = 'http://ruby_user_management:4567/api/auth/verify-token-user'
	
	@logger.log("Matchmaking", "user logged")
	http = EM::HttpRequest.new(uri).get(head: { 'Cookie' => "access_token=#{jwt}" })
	
	http.callback do
	  if http.response_header.status == 200
		callback.call(JSON.parse(http.response)) if callback
	  else
		@logger.log('App', "Failed to verify token: #{http.response_header.status} #{http.response_header.http_reason}")
		callback.call(nil) if callback
	  end
	end
  
	http.errback do
	  @logger.log('App', 'Failed to make the request due to a network error.')
	  callback.call(nil) if callback
	end
  end

end