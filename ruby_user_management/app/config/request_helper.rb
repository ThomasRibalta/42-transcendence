require 'json'
require_relative '../log/custom_logger'

module RequestHelper
  def self.parse_request(client)
    begin
      request = ''
      while (chunk = client.readpartial(2048))
        request += chunk
        break if chunk.length < 2048
      end
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

    # Parse cookies
    if headers['Cookie']
      headers['Cookie'].split('; ').each do |cookie|
        key, value = cookie.split('=', 2)
        cookies[key] = value if key && value
      end
    end
  
    # Parse body based on Content-Type
    content_type = headers['Content-Type']
    if content_type&.include?('application/json')
      begin
        body = JSON.parse(body) unless body.nil? || body.strip.empty?
      rescue JSON::ParserError
        return { error: 'Invalid JSON format' }
      end
    elsif content_type&.include?('multipart/form-data')
      # Parse multipart data
      boundary = "--#{content_type.split('boundary=')[-1]}"
      parts = body.split(boundary).map(&:strip).reject(&:empty?)
      body = {}
  
      parts.each do |part|
        part_header, part_body = part.split("\r\n\r\n", 2)
        part_body = part_body&.strip
        if part_header && part_body
          disposition = part_header.match(/Content-Disposition: form-data; name="([^"]+)"(; filename="([^"]+)")?/)
          name = disposition[1]
          filename = disposition[3]
  
          if filename  # File upload
            body[name] = { filename: filename, content: part_body }
          else  # Regular form field
            body[name] = part_body
          end
        end
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
