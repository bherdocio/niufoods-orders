module Orders
  class DashboardStats
    TOP_PRODUCTS = 5

    def total_sales
      Order.sum(:total_amount)
    end

    def average_ticket
      Order.average(:total_amount).to_i
    end

    def sales_by_restaurant
      Restaurant.left_joins(:orders)
                .group("restaurants.id", "restaurants.name")
                .order("restaurants.name")
                .pluck("restaurants.name", Arel.sql("COUNT(orders.id)"), Arel.sql("COALESCE(SUM(orders.total_amount), 0)"))
                .map { |name, count, amount| { label: name, count: count, amount: amount } }
    end

    def top_products
      Product.joins(:order_items)
             .group("products.id", "products.name")
             .order(Arel.sql("SUM(order_items.quantity) DESC"))
             .limit(TOP_PRODUCTS)
             .pluck("products.name", Arel.sql("SUM(order_items.quantity)"))
             .map { |name, quantity| { label: name, quantity: quantity } }
    end
  end
end
