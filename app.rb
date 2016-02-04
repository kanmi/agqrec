require 'bundler'
Bundler.setup

require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/json'

require_relative 'lib/config'
require_relative 'lib/clock'
require_relative 'lib/plugin'

Config.load
Plugin.init
Clockwork.reload!

class AGQREC < Sinatra::Base
  get '/' do
    send_file File.join(settings.public_folder, 'index.html')
  end
end

class API < Sinatra::Base
  get '/reload_clockwork' do
    Config.load
    Clockwork.reload!

    'reload!'
  end

  get '/available_schedules' do
    content_type :json

    registered_titles = nil
    params['all'] = params.keys.include?('all')
    unless params['all']
      registered_titles = Schedule.all.map { |schedule| schedule[:title] }.uniq
    end

    schedules = Plugin.all.map { |plugin|
      plugin.schedules.map { |schedule|
        schedule.merge(provider: plugin.to_s)
      }
    }.flatten.select { |schedule|
      params['provider'   ].tap { |p| break p ? schedule[:provider] == p     : true } && \
      params['title'      ].tap { |p| break p ? schedule[:title].include?(p) : true } && \
      params['personality'].tap { |p| break p ? schedule[:personality].include?(p) : true } && \
      params['all'        ].tap { |p| break p ? true : !registered_titles.include?(schedule[:title]) }
    }
    
    JSON.pretty_generate(schedules)
  end

  get '/schedules' do
    content_type :json
    schedules = Schedule.all
    schedules.select { |s| s[:provider] == params['provider'] } if params['provider']
    JSON.pretty_generate(schedules)
  end

  get '/schedules/:idx' do |idx|
    content_type :json
    JSON.pretty_generate(Schedule[idx.to_i])
  end

  post '/schedules' do
    [JSON.parse(request.body.read, symbolize_names: true )].flatten.each do |schedule|
      Schedule.add(schedule)
    end
    Schedule.save
    json status: 'ok'
  end

  put '/schedules' do
    [JSON.parse(request.body.read, symbolize_names: true )].flatten.each do |schedule|
      Schedule.update(schedule)
    end
    Schedule.save
    json status: 'ok'
  end

  delete "/schedules" do
    [JSON.parse(request.body.read, symbolize_names: true )].flatten.each do |schedule|
      Schedule.delete(schedule)
    end
    Schedule.save
    json status: 'ok'
  end
end
