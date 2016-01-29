require 'clockwork'

require_relative 'config'
require_relative 'schedule'

module Clockwork
  config = Config.new
  schedules = Schedule.new(config).all

  ( config.notification_methods +
    schedules.map { |s| s[:provider] }.uniq ).each do |name|
    require_relative "plugin/" + name
  end

  configure do |conf|
    conf[:thread] = true
  end
  
  schedules.each do |schedule|
	every(schedule[:interval].days, schedule[:title], at: schedule.to_clockwork_at) do
      sleep(60-(schedule[:margin]%60))
	  puts "Running #{schedule["title"]}, at #{}"
      Object.const_get(schedule[:provider]).record(schedule)
    end
  end
end
