require 'rubygems'
require 'bundler'
Bundler.setup
require 'sinatra'

get '/' do
  "Hello World"
end

run Sinatra::Application
