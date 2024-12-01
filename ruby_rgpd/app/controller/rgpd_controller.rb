require_relative '../service/rgpd_service'
require_relative '../config/request_helper'
require_relative '../log/custom_logger'

class RGPDController
  def initialize(rgpd_service = RGPDService.new)
    @rgpd_service = rgpd_service
  end

  def route_request(client, method, path, headers, body)
    case path
    when %r{^/restrict/(\d+)$}
      user_id = path.match(%r{^/restrict/(\d+)$})[1]
      handle_restrict(client, method, user_id)
    when %r{^/is_restricted/(\d+)$}
      user_id = path.match(%r{^/is_restricted/(\d+)$})[1]
      handle_is_restricted(client, method, user_id)
    when %r{^/portability/(\d+)$}
      user_id = path.match(%r{^/portability/(\d+)$})[1]
      handle_portability(client, method, user_id)
    else
      RequestHelper.not_found(client)
    end
  end

  private

  def handle_restrict(client, method, user_id)
    if method == 'POST'
      response = @rgpd_service.restrict_user(user_id)
      RequestHelper.respond(client, response[:code], response)
    else
      RequestHelper.not_found(client)
    end
  end

  def handle_is_restricted(client, method, user_id)
    if method == 'GET'
      response = @rgpd_service.is_restricted(user_id)
      RequestHelper.respond(client, response[:code], response)
    else
      RequestHelper.not_found(client)
    end
  end

  def handle_portability(client, method, user_id)
    if method == 'GET'
      response = @rgpd_service.portability(user_id)
      if response[:code] == 200
        client.puts "HTTP/1.1 200 OK"
        client.puts "Content-Type: text/csv"
        client.puts "Content-Disposition: attachment; filename=\"user_#{user_id}_data.csv\""
        client.puts
        client.puts response[:csv]
      else
        RequestHelper.respond(client, response[:code], response)
      end
    else
      RequestHelper.not_found(client)
    end
  end
end
