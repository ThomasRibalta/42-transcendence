require_relative '../../log/custom_logger'
require 'net/http'

class ImgApi
  def initialize(logger = CustomLogger.new)
    @logger = logger
  end

  def upload_img(image, user_id)
    uri = URI('http://image_ruby:4572/img/upload')
    req = Net::HTTP::Post.new(uri)
    filetype = File.extname(image[:filename])
    filename = "#{user_id}#{filetype}"
    encoded_content = Base64.strict_encode64(image[:content])
    image_json = { "id": user_id, "filename": filename, "content": encoded_content }.to_json
    req.content_type = 'application/json'
    req.body = image_json
    http = Net::HTTP.new(uri.host, uri.port)
    res = http.start do |http|
      http.request(req)
    end
    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    else
      @logger.log('App', "Failed to verify token: #{res.code} #{res.message}")
      false
    end
  end

  def delete_img(user_id)
    uri = URI("http://image_ruby:4572/img/delete/#{user_id}")
    req = Net::HTTP::Post.new(uri)
    req.content_type = 'application/json'
  
    http = Net::HTTP.new(uri.host, uri.port)
    
    begin
      res = http.start { |http| http.request(req) }
      if res.is_a?(Net::HTTPSuccess)
        JSON.parse(res.body)
      else
        @logger.log('App', "Échec de la suppression de l'image: #{res.code} #{res.message}")
        false
      end
    rescue JSON::ParserError
      @logger.log('App', "Réponse non-JSON pour la suppression d'image user_id=#{user_id}")
      false
    rescue StandardError => e
      @logger.log('App', "Erreur inattendue lors de la suppression de l'image: #{e.message}")
      false
    end
  end
  
  
  
end