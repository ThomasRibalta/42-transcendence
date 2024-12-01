require 'logstash-logger'
require 'tzinfo'

# Define the CustomLogger class
class CustomLogger
  def initialize(
    logstash_host = 'logstash',
    logstash_port = 5001,
    timezone = 'Europe/Paris'
  )
    @timezone = TZInfo::Timezone.get(timezone)
    @logger = LogStashLogger.new(
      type: :tcp,
      host: logstash_host,
      port: logstash_port,
      formatter: proc do |severity, datetime, progname, msg|
        localized_time = @timezone.utc_to_local(datetime)
        {
          '@timestamp' => localized_time.iso8601,
          'level' => severity,
          'where' => progname,
          'message' => msg,
          'service' => 'ruby_user_management'
        }.to_json + "\n"
      end
    )
  end

  def log(where, message, level = 'INFO')
    @logger.add(::Logger.const_get(level), message, where)
  end
end