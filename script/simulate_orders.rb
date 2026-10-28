require "json"
require "net/http"
require "uri"

class OrderSimulator
  PRODUCT_IDS = (1..10).to_a.freeze
  RESTAURANT_IDS = [1, 2, 3].freeze
  CUSTOMERS = [
    { name: "Ana Pérez", phone: "+56912345678" },
    { name: "Juan Soto", phone: "+56987654321" },
    { name: "Camila Rojas", phone: "+56911223344" },
    { name: "Diego Muñoz", phone: "+56955667788" }
  ].freeze
  ADDRESSES = [
    "Av. Providencia 1234, Santiago",
    "Av. Apoquindo 4500, Las Condes",
    "Irarrázaval 2800, Ñuñoa",
    "Av. Grecia 1500, Ñuñoa"
  ].freeze
  INVALID_CASES = %i[delivery_without_address zero_quantity unknown_product].freeze
  INVALID_EVERY = 5

  def initialize(count:, api_url:)
    @count = count
    @uri = URI.join(api_url, "/api/v1/orders")
    @results = Hash.new(0)
  end

  def run
    puts "Enviando #{count} órdenes a #{uri}"
    puts

    count.times do |index|
      number = index + 1
      payload = (number % INVALID_EVERY).zero? ? invalid_order(number) : valid_order
      send_order(number, payload)
    end

    print_summary
    results[:failed].zero?
  end

  private

  attr_reader :count, :uri, :results

  def valid_order
    order_type = %w[pickup delivery].sample
    order = {
      restaurant_id: RESTAURANT_IDS.sample,
      order_type: order_type,
      customer: CUSTOMERS.sample,
      items: PRODUCT_IDS.sample(rand(1..4)).map { |id| { product_id: id, quantity: rand(1..3) } }
    }
    order[:delivery_address] = ADDRESSES.sample if order_type == "delivery"
    order
  end

  def invalid_order(number)
    order = valid_order

    case INVALID_CASES[(number / INVALID_EVERY - 1) % INVALID_CASES.size]
    when :delivery_without_address
      order.merge(order_type: "delivery").except(:delivery_address)
    when :zero_quantity
      order.merge(items: [{ product_id: PRODUCT_IDS.sample, quantity: 0 }])
    when :unknown_product
      order.merge(items: [{ product_id: 999, quantity: 1 }])
    end
  end

  def send_order(number, payload)
    response = post(payload)
    body = parse(response.body)

    case response.code.to_i
    when 201
      results[:created] += 1
      puts format("#%03d OK    orden %d · %s · %-8s · $%s", number, body["id"], body.dig("restaurant", "code"), body["order_type"], format_clp(body["total_amount"]))
    when 422
      results[:rejected] += 1
      puts format("#%03d 422   %s", number, Array(body["errors"]).join("; "))
    else
      results[:failed] += 1
      puts format("#%03d HTTP %d %s", number, response.code.to_i, response.body.to_s[0, 200])
    end
  rescue SystemCallError, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    results[:failed] += 1
    puts format("#%03d ERROR %s: %s", number, e.class, e.message)
  end

  def post(payload)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 2
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.request_uri, "Content-Type" => "application/json")
    request.body = JSON.generate(payload)
    http.request(request)
  end

  def parse(body)
    JSON.parse(body.to_s)
  rescue JSON::ParserError
    {}
  end

  def format_clp(amount)
    amount.to_i.to_s.reverse.scan(/\d{1,3}/).join(".").reverse
  end

  def print_summary
    puts
    puts "Resumen: #{results[:created]} creadas, #{results[:rejected]} rechazadas por validación, #{results[:failed]} con error"
  end
end

if $PROGRAM_NAME == __FILE__
  srand(Integer(ENV["SEED"])) if ENV["SEED"]
  count = Integer(ARGV[0] || 20)
  api_url = ARGV[1] || ENV.fetch("API_URL", "http://localhost:3000")
  exit(OrderSimulator.new(count: count, api_url: api_url).run ? 0 : 1)
end