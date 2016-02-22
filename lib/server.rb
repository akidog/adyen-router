adyen_router_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(adyen_router_path) unless $LOAD_PATH.include? adyen_router_path

require 'adyen_router/version'
require 'adyen_router/node'
require 'yaml'
require 'sinatra/base'
require 'base64'
require 'net/http'

module AdyenRouter
  class Server < Sinatra::Base

  set :bind, '0.0.0.0'

  @@clients = []

  helpers do
    def protected!
      return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV['USER'], ENV['PASSWORD']]
    end
  end

  get '/settings' do
    protected!

    html = "<h1>Server settings</h1>"
    html += "<h2> Published Machines </h2>"
    html += "<ol>"
    @@clients.each do |m|
      html += "<li>name: #{m.id}<br>host: #{m.host}<br>port: #{m.port}<br> post_path: #{m.post_path} <br></li>"
    end
    html += "</ol>"
    erb html
  end

  post '/publish' do
    new_node = AdyenRouter::Node.new *::Base64::decode64(params[:node]).split("|")

    @@clients << new_node unless @@clients.include?(new_node)
    @@clients.map do |node|
      new_node if node.eql?(new_node)
    end

    [200, {},"AdyenRouter: Yay! Notifications for #{new_node.id} will be forward to #{new_node.id}:#{new_node.port}\n"]
  end

  post '/' do

    protected!

    node = fetch_node(params[:merchantReference].scan(/[dev|test]-(.*)::/).flatten.first.to_s)

    puts node.inspect
    uri = URI("http://#{node.host}:#{node.port}/#{node.post_path}")

    post_back_proxy = ::Net::HTTP::Post.new(uri, intercept_headers)
    post_back_proxy.set_form_data params

    response = ::Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(post_back_proxy)
    end

    case response
    when ::Net::HTTPSuccess
      [200, {}, response.body]
    else
      halt 404, "not available"
    end

  end


  private

  def fetch_node(id)
    halt = Proc.new { |id| halt 500, "AdyenRouter - Node #{id} not found" }
    return @@clients.detect(halt.call(id)) { |n| n.id.eql?(id) }
  end

  def intercept_headers
    {
      'VERSION'       => env['HTTP_VERSION'],
      'AUTHORIZATION' => env['HTTP_AUTHORIZATION'],
      'USER_AGENT'    => env['HTTP_USER_AGENT']
    }
  end

  # start the server if ruby file executed directly
    run! if app_file == $0
  end


end
