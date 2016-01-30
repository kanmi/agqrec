require 'bundler'
Bundler.setup

require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/json'

require_relative 'lib/config'
require_relative 'lib/clock'

Config.load
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
    json status: 'ok'
  end

  put '/schedules' do
    [JSON.parse(request.body.read, symbolize_names: true )].flatten.each do |schedule|
      Schedule.update(schedule)
    end
    json status: 'ok'
  end

  delete "/schedules/:title" do |title|
    Schedule.delete(title)
    JSON.pretty_generate(Schedule.all)
  end
end
