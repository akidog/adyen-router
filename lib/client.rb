require "adyen_router/version"
require 'open-uri'
require 'net/http'
require 'base64'

module AdyenRouter

    def self.configure(&block)
      @client = Client.new
      @client.instance_eval &block
      @client.publish
    end

  class Client

    attr_writer   :machine_identity, :machine_host, :machine_port
    attr_accessor :machine_use_private_address, :machine_post_path, :router_url

    def identity
      @machine_identity ||= Socket.gethostname
    end

    def host
      if !@machine_host.nil?
        @machine_host
      elsif local_network?
        Socket.ip_address_list.detect {|ip| ip.ipv4_private? }.ip_address
      else
        public_ip_address
      end
    end

    def port
      @machine_port ||= 3000
    end

    def post_path
      @machine_post_path ||= 'adyen/post_back'
    end

    def local_network?
      machine_use_private_address
    end

    def public_ip_address
      begin
        remote_ip = open('http://whatismyip.akamai.com').read
      rescue Exception => e
        puts 'Service down or unavailable! Trying to use the provided ip address'
        raise 'Could not find a valid host! Have you tried setting your own?'
      end
    end

    def publish
      protocol = router_url.scan(/(http):\/\/|(https):\/\//).flatten.compact.first
      router_url.gsub!(/http:\/\/|https:\/\//, '')
      protocol = "http" unless protocol
      uri = URI("#{protocol}://#{router_url}/publish")

      req = Net::HTTP::Post.new(uri)
      req.set_form_data(machine: Base64.encode64("#{identity}|#{host}|#{port}|#{post_path}"))

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      puts res.body

    end

  end
end
