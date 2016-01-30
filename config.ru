require 'sinatra'
require './app'

run Rack::URLMap.new({ '/' => AGQREC, '/api' => API})
