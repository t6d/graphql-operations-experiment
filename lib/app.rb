require 'sinatra/base'
require 'sinatra/reloader'
require 'rack/parser'

require 'graphql'
require 'smart_properties'
require 'active_operation'

class Notebook
  include SmartProperties

  property :id
  property :title

  def to_json
    {
      id: id,
      title: title
    }.to_json
  end
end

class GraphQLOperation < ActiveOperation::Base
  def self.call(object, arguments, context)
    super(object: object, arguments: arguments, context: context)
  end
end

class Notebook::Find < GraphQLOperation
  input :object, type: :keyword
  input :arguments, type: :keyword
  input :context, type: :keyword

  def execute
    Notebook.new(id: arguments[:id], title: "Some randome title")
  end
end

##
# Schema definition
##

NotebookType = GraphQL::ObjectType.define do
  name "Notebook"
  description "A notebook"

  field :id, types.ID
  field :title, types.String
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root for this schema"

  field :notebook do
    type NotebookType
    argument :id, !types.ID
    resolve Notebook::Find
  end
end

Schema = GraphQL::Schema.define(query: QueryType)

##
# Application
##

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

    query_string = params.fetch("query", "")
    query_variables = params.fetch("variables", {})

    Schema.execute(query_string, variables: query_variables).to_json
  end
end
