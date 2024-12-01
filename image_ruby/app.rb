require 'webrick'
require 'mongo'
require 'base64'
require 'json'
require_relative 'app/log/custom_logger'

logger = Logger.new
logger.log('Server', 'Starting server')

client = Mongo::Client.new('mongodb://user:password@mongodb:27017/ft_transcendence_db?authSource=admin')
logger.log('Mongo', 'Connected to database')

images_collection = client[:images]

logger.log('Server', 'Collections created')

def mime_type_from_extension(filename)
  case File.extname(filename).downcase
  when '.png'
    'image/png'
  when '.jpg', '.jpeg'
    'image/jpeg'
  when '.gif'
    'image/gif'
  when '.bmp'
    'image/bmp'
  when '.svg'
    'image/svg+xml'
  else
    'application/octet-stream'
  end
end

server = WEBrick::HTTPServer.new(Port: 4572)

server.mount_proc '/' do |req, res|
  logger.log('Server', "Request for #{req.path}")
  res.body = 'Hello, world ! /'
end

server.mount_proc '/img/upload' do |req, res|
  logger.log('Server', "Request for #{req.path} with method #{req.request_method}")
  if req.request_method == 'POST'
    json = JSON.parse(req.body)
    image_name = json['filename']
    image_doc = images_collection.find(id: json['id']).first
    if image_doc
      images_collection.delete_one(id: json['id'])
    end
    mime_type = mime_type_from_extension(image_name)

    images_collection.insert_one({ id: json['id'], filename: image_name, content: json['content'], mime_type: mime_type })

    logger.log('Server', "Received image: #{req.body}")
    res.body = "{ \"img_url\": \"https://localhost/img/#{image_name}\" }"
  else
    res.body = "Erreur lors du traitement de l'image."
  end
end

server.mount_proc '/img/' do |req, res|
  image_name = req.path.sub('/img/', '')
  image_doc = images_collection.find(filename: image_name).first

  if image_doc
    res.content_type = image_doc[:mime_type]
    res.body = Base64.strict_decode64(image_doc[:content])
  else
    res.status = 404
    res.body = 'Image not found'
  end
end

server.mount_proc '/img/delete/' do |req, res|
  image_name = req.path.sub('/img/delete/', '')

  image_doc = images_collection.find(filename: /^#{Regexp.escape(image_name)}(\..+)?$/).first

  if image_doc
    images_collection.delete_one(filename: image_doc[:filename])
    res.body = 'Image deleted'
    logger.log('Server', "Image '#{image_doc[:filename]}' supprimée")
  else
    res.status = 404
    res.body = 'Image not found'
    logger.log('Server', "Image '#{image_name}' introuvable")
  end
end


trap('INT') { server.shutdown }

server.start
