require 'sinatra/base'

class App < Sinatra::Base
  enable :static
  set :root, File.expand_path("../..", __FILE__)

  get "/" do
    erb :index
  end

  post "/api" do
    content_type "application/json"
    "{}"
  end
end
