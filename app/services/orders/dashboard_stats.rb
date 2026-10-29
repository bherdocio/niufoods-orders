module Orders
  class DashboardStats
    TOP_PRODUCTS = 5
    HOURLY_SPAN_SECONDS = 24 * 60 * 60

    def initialize(orders, restaurants, from: nil, to: nil)
      @orders = orders
      @restaurants = restaurants
      @from = from
      @to = to
    end

    def total_sales
      orders.sum(:total_amount)
    end

    def average_ticket
      orders.average(:total_amount).to_i
    end

    def status_counts
      orders.group(:dispatch_status).count
    end

    def sales_by_restaurant
      totals = orders.group(:restaurant_id)
                     .pluck(:restaurant_id, Arel.sql("COUNT(*)"), Arel.sql("SUM(total_amount)"))
                     .to_h { |id, count, amount| [ id, { count: count, amount: amount } ] }

      restaurants.map do |restaurant|
        totals.fetch(restaurant.id, { count: 0, amount: 0 }).merge(label: restaurant.name)
      end
    end

    def top_products
      OrderItem.joins(:product)
               .where(order_id: orders.select(:id))
               .group("products.id", "products.name")
               .order(Arel.sql("SUM(order_items.quantity) DESC"), "products.name")
               .limit(TOP_PRODUCTS)
               .pluck("products.name", Arel.sql("SUM(order_items.quantity)"))
               .map { |name, quantity| { label: name, quantity: quantity } }
    end

    def sales_over_time
      rows = orders.pluck(:created_at, :total_amount)
      return [] if rows.empty?

      times = rows.map { |time, _| time.in_time_zone }
      first = from ? from.in_time_zone.beginning_of_day : times.min
      last = to ? [ to.in_time_zone.end_of_day, Time.current ].min : times.max
      hourly = last - first <= HOURLY_SPAN_SECONDS
      buckets = hourly ? hourly_buckets(first, last) : (first.to_date..last.to_date).to_a

      sums = Hash.new(0)
      rows.each { |time, amount| sums[bucket_key(time.in_time_zone, hourly)] += amount }

      buckets.map do |bucket|
        { label: bucket.strftime(hourly ? "%H:%M" : "%d-%m"), value: sums[bucket_key(bucket, hourly)] }
      end
    end

    private

    attr_reader :orders, :restaurants, :from, :to

    def hourly_buckets(first, last)
      start = first.beginning_of_hour
      hours = ((last.beginning_of_hour - start) / 3600).to_i
      (0..hours).map { |offset| start + offset.hours }
    end

    def bucket_key(time, hourly)
      hourly ? time.beginning_of_hour.to_i : time.to_date
    end
  end
end
