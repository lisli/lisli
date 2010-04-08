require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'

set :sass, { :style => :compact }

get "/styles.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

helpers do
  def current_tab_if(route)
    "current" if request.path_info == route
  end
end

get "/" do
  haml :home
end

get "/:page/?" do
  begin
    haml params[:page].to_sym
  rescue Errno::ENOENT
    haml :home
  end
end
