module AdyenRouter
  class Node

    attr_writer :id, :host, :port, :post_path

    def initialize(id, host, port, post_path)
      @id, @host, @port, @post_path = id, host, port, post_path
    end

    def id
      @id || Socket.gethostname
    end

    def host
      @host || Node.public_address
    end

    def port
      @port || 3000
    end

    def post_path
      @post_path || 'adyen/post_back'
    end

    def self.public_ip_address
      begin
        remote_ip = open('http://whatismyip.akamai.com').read
      rescue Exception => e
        puts 'Service down or unavailable! Trying to use the provided ip address'
        raise 'Could not find a valid host! Have you tried setting your own?'
      end
    end

  end
end
