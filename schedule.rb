require 'json'

class Schedule
  include Enumerable
  
  def initialize(schedule_file = "./schedule.json")
    schedule = JSON.parse(File.read(schedule_file)) rescue []
    @schedule = schedule.map do |s|
      {
        title: s['title'],
        from: s['from'],
        to: s['to'],
        sound_only: s['sound_only'] || false
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
