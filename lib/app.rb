require 'sinatra/base'

class App < Sinatra::Base
  get '/' do
    content_type 'text/plain'
    'Hello World'
  end
end
