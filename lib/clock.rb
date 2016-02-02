require 'clockwork'

require_relative 'config'
require_relative 'schedule'

module Clockwork
  @init_proc = Proc.new do
    schedules = Schedule.all

    schedules.map { |s| s[:provider] }.uniq.each do |name|
      next if name.nil?
      require_relative "../plugin/" + name
      Object.const_get(name).init
    end

    configure do |conf|
      conf[:thread] = true
    end
    
    schedules.each do |schedule|
      if schedule[:provider] && Object.const_get(schedule[:provider])
	    every(schedule[:interval].days, schedule[:title], at: schedule.to_clockwork_at) do
          sleep(60-(schedule[:margin]%60))
          Object.const_get(schedule[:provider]).run(schedule)
        end
      else
        puts "Failed to find provider '#{schedule[:provider]}'"
      end
    end
  end

  class << self
    def reload!
      Clockwork.kill
      Clockwork.clear!
      @init_proc.call
      Clockwork.run
    end

    alias_method :run_orig, :run
    def run
      @clockwork_thread = Thread.start { self.run_orig }
    end

    def kill
      @clockwork_thread.kill if @clockwork_thread
    end
  end
end
