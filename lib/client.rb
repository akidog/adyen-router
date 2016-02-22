require "adyen_router/version"
require 'adyen_router/node'
require 'open-uri'
require 'net/http'
require 'base64'

module AdyenRouter

  def self.configure(&block)
    @client = Client.new
    @client.instance_eval &block
    @client
  end

  class Client

    attr_accessor :url

    def initialize
      @nodes = []
    end

    def node(&blk)
      @nodes << Node.new
      @nodes.last.instance_eval &blk
    end

    def publish
      url ~= /(http|https):\/\/.*/
      raise 'Enter FQDN ! Missing protocol, http or https?' unless $1
      @nodes.each do |node|
        uri = URI("#{url}/publish")

        req = Net::HTTP::Post.new(uri)
        req.set_form_data(node: Base64.encode64("#{node.id}|#{node.host}|#{node.port}|#{node.post_path}"))

        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end

        puts res.body
      end
    end


  end
end
