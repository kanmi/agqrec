require 'json'

class Config
  attr_accessor :notification_methods, :save_path, :schedule_file, :time_format

  def initialize(conf_file = "./config.json")
    @conf_file = conf_file
    conf = JSON.parse(File.read(conf_file)) rescue {}

    @notification_methods = conf['notification_methods'] ? [conf['notification_methods']].flatten : []
    @save_path = conf['save_path'] || "./record/%{title}/%{time} - %{title}"
    @schedule_file = conf['schedule_file'] || "./schedule.json"
    @time_format = conf['time_format'] || '%Y-%m-%d'
  end

  def save
    File.write(@conf_file, to_h.to_json)
  end

  def to_h
    {
      notification_methods: @notification_methods,
      save_path: @save_path,
      schedule_file: @schedule_file,
      time_format: @time_format
    }
  end
end
