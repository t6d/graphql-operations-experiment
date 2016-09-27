require 'sinatra/base'
require 'sinatra/reloader'
require 'rack/parser'

class App < Sinatra::Base
  enable :static
  set :root, File.expand_path("../..", __FILE__)

  configure :development do
    require 'pry'
    register Sinatra::Reloader
  end

  use Rack::Parser, content_types: {
    'application/json'  => Proc.new { |body| ::MultiJson.decode body }
  }

  get "/" do
    erb :index
  end

  post "/api" do
    content_type "application/json"
    "{}"
  end
end
