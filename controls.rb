require 'rubygems'
require 'sinatra'
require 'sass'

set :sass, { :style => :compact }

get "/styles.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

before do
  @first_name = "Chad"
  @full_name = "Chad Ostrowski"
end

get "/" do
  haml :home
end

get "/:page/?" do
  haml :params[:name]
end
