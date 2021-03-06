begin
  # Require the preresolved locked set of gems.
  require ::File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on doing the resolve at runtime.
  require "rubygems"
  require "bundler"
  Bundler.setup
end

require 'sinatra'
require 'sinatra/base'
require 'rack'
require 'haml'
require 'sass'
require 'partials'
require 'open-uri'
require 'crack'
require 'rack-flash'
require 'pony'
require 'sinatra/content_for'
require 'mollom'

enable :sessions

set :sass, { :style => :compact }
set :haml, { :ugly => true }

get "/styles.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :styles
end

helpers do
  include Sinatra::Partials
  use Rack::Flash, :accessorize => [:notice]

  #Helper function to add class="current" to the active tab
  #Allows passing in either a simple string with the route name
  #to flag on,
  #or an array of strings if multiple states receive a flag
  def current_tab_if(route)
    flag = ""
    if route.respond_to? :each
      for x in route
        flag = "current" if request.path_info == x
      end
    else
      flag = "current" if request.path_info == route
    end
    flag
  end
  
  #Helper to turn date returned from blogger into a ruby date. Assumes Eastern Standard Time (New York)
  #Assumes format like this: 2009-11-16T23:28:00.000-05:00
  #
  #TODO: It would be nice to generalize this to deal with any iso formatted string,
  #make it extend the Time class,
  #and turn it into a gem.
  def time_from_iso_format_str(iso_8601_string)
    iso_8601_string [/(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/];
    y=$1;mon=$2;d=$3;h=$4;min=$5;s=$6
    Time.local(y,mon,d,h,min,s)
  end

  #Extend Hash class so that keys can be accessed as attributes, with dot notation.
  #Courtesy of http://www.goodercode.com/wp/convert-your-hash-keys-to-object-properties-in-ruby/
  class ::Hash
    def method_missing(name)
      return self[name] if key? name
      self.each { |k,v| return v if k.to_s.to_sym == name }
      super.method_missing name
    end
  end
end

get "/" do
  haml :language_assistance
end

#loads in blogger feed
get "/thoughts" do
  #for testing in irb:
  #require 'open-uri'; require 'crack'; url = 'http://www.blogger.com/feeds/9096209599953091034/posts/default?max-results=10';xml = open(url).read;feed = Crack::XML.parse(xml).feed;posts = feed.entry;
  url = 'http://www.blogger.com/feeds/9096209599953091034/posts/default?max-results=11'
  xml = open(url).read
  feed = Crack::XML.parse(xml).feed
  @posts = feed.entry
  
  #make work when offline, give an error
  
  haml :thoughts
end

get "/:page/?" do
  begin
    haml params[:page].to_sym
  rescue Errno::ENOENT
    haml :not_found
  end
end

not_found do
  haml :not_found
end

post "/contact" do
  #backend form validation in Sinatra?
  #put it here!
#  m = Mollom.new(:private_key => 'none yet', :public_key => 'ni esto')
#
#  content = m check_content(:post_body => params[:message], :author_name => params[:name])
#
#  if content.spam?
#    flash.now[:notice] = "Sorry, that message seemed like it was written by a robot. Are you a robot? Go away! Otherwise, write something less spammy, please!"
#    haml :contact
#  elsif content.unsure?
#    flash.now[:notice] = "Hmm... You might be a robot? It's hard to tell, these days. Please verify your humanity."
#    @mollom = m.image_captcha(:session_id => content.session_id)["url"]
#    
#    #check captcha response before all of this, put @mollom in page
#
#    haml:contact
#  else
    Pony.mail :to => 'chad.ostrowski@gmail.com',
      :from => '"' + params[:name] + '" <' + params[:email] + '>',
      :body => params[:message],
      :subject => "Mail from Lisli.net!",
      :via => :smtp,
      :via_options => { :address => 'smtp.sendgrid.net',
        :port => '25',
        :authentication => :plain,
        :user => ENV['SENDGRID_USERNAME'],
        :password => ENV['SENDGRID_PASSWORD'],
        :domain => ENV['SENDGRID_DOMAIN']
      }
    flash.now[:notice] = "Thanks for your message! I'll get back to you soon."
    haml :contact
#  end
end
