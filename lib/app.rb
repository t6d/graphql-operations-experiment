require 'sinatra/base'
require 'sinatra/reloader'

class App < Sinatra::Base
  enable :static
  set :root, File.expand_path("../..", __FILE__)

  configure :development do
    require 'pry'
    register Sinatra::Reloader
  end

  get "/" do
    erb :index
  end

  post "/api" do
    content_type "application/json"
    "{}"
  end
end
