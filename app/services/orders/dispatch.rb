require "net/http"

module Orders
  class Dispatch
    class RetryableError < StandardError; end

    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    def self.call(order)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      handle(post)
    rescue Net::OpenTimeout, Net::ReadTimeout, SystemCallError, SocketError, IOError => e
      register_attempt(success: false, error_message: "#{e.class}: #{e.message}")
      raise RetryableError, e.message
    end

    private

    attr_reader :order

    def post
      uri = URI.parse(order.restaurant.dispatch_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Post.new(
        uri.request_uri,
        "Content-Type" => "application/json",
        "Idempotency-Key" => "order-#{order.id}"
      )
      request.body = OrderSerializer.new(order).as_json.to_json
      http.request(request)
    end

    def handle(response)
      status = response.code.to_i

      if status.between?(200, 299)
        register_attempt(success: true, response_status: status)
        order.update!(dispatch_status: :sent, dispatched_at: Time.current)
      elsif status.between?(400, 499)
        register_attempt(success: false, response_status: status, error_message: response.body.to_s.truncate(500))
        order.update!(dispatch_status: :failed)
      else
        register_attempt(success: false, response_status: status, error_message: response.body.to_s.truncate(500))
        raise RetryableError, "La tienda respondió #{status}"
      end
    end

    def register_attempt(success:, response_status: nil, error_message: nil)
      order.dispatch_attempts.create!(success: success, response_status: response_status, error_message: error_message)
    end
  end
end
