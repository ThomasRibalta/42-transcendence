require 'json'

module RequestHelper
  def self.parse_request(client)
    begin
      request = client.readpartial(2048)
    rescue EOFError
      return nil
    end
    return nil if request.lines.empty?

    method, path, _version = request.lines[0].split
    headers = {}
    cookies = {}
    body = nil

    request.lines[1..-1].each_with_index do |line, index|
      if line.strip.empty?
        body = request.lines[(index + 2)..-1].join
        break
      end
      header, value = line.split(': ', 2)
      headers[header] = value.strip if header && value
    end

    if headers['Cookie']
      headers['Cookie'].split('; ').each do |cookie|
        key, value = cookie.split('=', 2)
        cookies[key] = value if key && value
      end
    end

    if headers['Content-Type'] && headers['Content-Type'].include?('application/json')
      begin
        body = JSON.parse(body) unless body.nil? || body.strip.empty?
      rescue JSON::ParserError
        return { error: 'Invalid JSON format' }
      end
    end

    [method, path, headers, cookies, body]
  end


  def self.respond(client, status, message, cookies = nil)
    client.puts "HTTP/1.1 #{status}"
    client.puts "Content-Type: application/json"
    if cookies
      cookies.each do |cookie|
        client.puts "Set-Cookie: #{cookie}"
      end
    end
    client.puts
    client.puts message.is_a?(String) ? { message: message }.to_json : message.to_json
  end

  def self.not_found(client)
    respond(client, 404, { error: 'UserManagement : Not Found' })
  end
end
