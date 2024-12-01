require 'tzinfo'

class Logger
  def initialize(log_file = "app.log", timezone = 'Europe/Paris')
    @log_file = log_file
    @timezone = TZInfo::Timezone.get(timezone)
  end

  def log(where, message)
    File.open(@log_file, "a") do |file|
      file.puts("[#{current_time}] - #{where} => #{message}")
    end
  end

  private

  def current_time
    @timezone.now.strftime("%Y-%m-%d %H:%M:%S")
  end
end
