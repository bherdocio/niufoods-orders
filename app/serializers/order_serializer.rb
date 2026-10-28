class OrderSerializer
  def initialize(order)
    @order = order
  end

  def as_json(*)
    {
      id: order.id,
      restaurant: { id: order.restaurant.id, code: order.restaurant.code, name: order.restaurant.name },
      order_type: order.order_type,
      customer: { name: order.customer_name, phone: order.customer_phone },
      delivery_address: order.delivery_address,
      total_amount: order.total_amount,
      dispatch_status: order.dispatch_status,
      created_at: order.created_at,
      items: order.order_items.map do |item|
        {
          product_id: item.product_id,
          sku: item.product.sku,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.unit_price,
          subtotal: item.subtotal
        }
      end
    }
  end

  private

  attr_reader :order
end
