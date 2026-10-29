module OrderHelpers
  def build_order(restaurant: restaurants(:providencia), items: { products(:salmon_roll) => 2 }, **attributes)
    order = Order.new({ restaurant: restaurant, order_type: "pickup", customer_name: "Ana Pérez" }.merge(attributes))
    items.each { |product, quantity| order.order_items.build(product: product, quantity: quantity) }
    order
  end
end
