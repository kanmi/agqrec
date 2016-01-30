require 'json'
require_relative 'config'

module Schedule
  include Enumerable
  
  class << self
    def schedules
      @schedules ||= reload
    end

    def reload
      @schedules = (JSON.parse(File.read(Config.schedule_file), symbolize_names: true) rescue []).map do |s|
        s.tap { |_|
          _[:interval] ||= 7
          _[:margin]   ||= 15
          def _.to_clockwork_at
            (DateTime.parse(self[:at]) - (self[:margin] || Config.margin).seconds).strftime("%A %R")
          end
          break _
        }
      end
    end

    def add(schedule)
      schedules << schedule
    end

    def update(schedule)
      idx = schedules.index { |s| s[:title] == schedule[:title] }
      return if schedules[idx].nil?
      schedules[idx] = schedule 
      schedules[idx]
    end

    def delete(title)
      schedules.delete_if { |s| s[:title] == title }
    end

    def clear
      @schedule = []
    end

    def save
      File.write(Config.schedule_file, JSON.pretty_generate(schedule))
    end
  end

  module Methods
    def [](idx)
      schedules[idx]
    end

    def each &block
      schedules.each(&block)
    end

    def all
      schedules
    end
  end
  extend Methods
end
