module AdyenRouter

  class Machine

    attr_reader :name, :host, :port, :post_path

    def initialize(name, host, port, post_path)
      @name, @host, @port, @post_path = name, host, port, post_path
    end

  end


end
