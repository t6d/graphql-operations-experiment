require 'sinatra/base'
require 'sinatra/reloader'
require 'rack/parser'

require 'graphql'
require 'smart_properties'
require 'active_operation'

##
# Models
##

class Notebook
  include SmartProperties

  property :id
  property :title

  @notebooks = []

  def self.find(id)
    @notebooks.find { |notebook| notebook.id.to_s == id.to_s }
  end

  def self.create(**attrs)
    new(id: @notebooks.length + 1, **attrs).tap do |new_notebook|
      @notebooks << new_notebook
    end
  end

  def to_h
    {
      id: id,
      title: title
    }
  end

  def to_json
    to_h.to_json
  end
end

##
# Operation supertypes
##

class Operation < ActiveOperation::Base
  def self.option(name, **config)
    input(name, type: :keyword, **config)
  end
end

class QueryOperation < Operation
  option :object
  option :context

  def self.call(object, arguments, context)
    super(object: object, context: context, **arguments.to_h.map { |k,v| [k.to_sym, v] }.to_h)
  end
end

class MutationOperation < Operation
  option :context

  def self.call(inputs, context)
    super(context: context, **inputs.to_h.map { |k,v| [k.to_sym, v] }.to_h)
  end
end

##
# Business processes
##

class Notebook::Find < QueryOperation
  option :id

  def execute
    Notebook.find(id)
  end
end

class Notebook::Create < MutationOperation
  option :title

  def execute
    Notebook.create(title: title)
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

CreateNotebookMutation = GraphQL::Relay::Mutation.define do
  name "CreateNotebook"
  input_field :title, !types.String
  return_field :id, types.ID
  return_field :title, types.String
  resolve Notebook::Create
end

MutationType = GraphQL::ObjectType.define do
  name "Mutation"
  description "The mutation root for this schema"

  field :createNotebook, CreateNotebookMutation.field
end

Schema = GraphQL::Schema.define do
  query QueryType
  mutation MutationType
end

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
