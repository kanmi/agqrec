require 'json'
require_relative 'config'

class Schedule
  include Enumerable
  
  def initialize(config = Config.new)
    schedule = JSON.parse(File.read(config.schedule_file)) rescue []
    @schedule = schedule.map do |s|
      {
        title: s['title'],
        from: s['from'],
        to: s['to'],
        sound_only: s['sound_only'] || false,
        margin: s['margin'] || config.margin
      }
    end
  end

  def [](idx)
    @schedule[idx]
  end

  def each &block
    @schedule.each(&block)
  end
end
