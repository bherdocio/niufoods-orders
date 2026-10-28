module Orders
  class Create
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    def call
      order = build_order
      enqueue_dispatch(order) if order.save
      order
    end

    private

    attr_reader :params

    def build_order
      order = Order.new(
        restaurant_id: params[:restaurant_id],
        order_type: params[:order_type],
        delivery_address: params[:delivery_address],
        customer_name: params.dig(:customer, :name),
        customer_phone: params.dig(:customer, :phone)
      )

      Array(params[:items]).each do |item|
        order.order_items.build(product_id: item[:product_id], quantity: item[:quantity])
      end

      order
    end

    def enqueue_dispatch(order)
      DispatchOrderJob.perform_async(order.id)
    rescue RedisClient::CannotConnectError => e
      Rails.logger.error("No se pudo encolar el despacho de la orden #{order.id}: #{e.message}")
    end
  end
end
