module AdyenRouter
  class Node

    attr_accessor :id, :host, :port, :post_path

    def initialize(id=Socket.gethostname, host=Node.public_ip_address, port=3000, post_path='adyen/post_back')
      @id, @host, @port, @post_path = id, host, port, post_path
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
