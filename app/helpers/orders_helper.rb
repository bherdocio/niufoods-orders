module OrdersHelper
  DISPATCH_STATUS_LABELS = { "pending" => "Pendiente", "sent" => "Enviado", "failed" => "Error" }.freeze
  ORDER_TYPE_LABELS = { "pickup" => "Retiro", "delivery" => "Delivery" }.freeze

  def dispatch_status_label(status)
    DISPATCH_STATUS_LABELS.fetch(status.to_s, status.to_s)
  end

  def dispatch_status_badge(order)
    content_tag(:span, dispatch_status_label(order.dispatch_status), class: "badge badge-#{order.dispatch_status}")
  end

  def order_type_label(order)
    ORDER_TYPE_LABELS.fetch(order.order_type, order.order_type)
  end

  def clp(amount)
    number_to_currency(amount, unit: "$", delimiter: ".", precision: 0, format: "%u%n")
  end

  def format_time(time)
    time ? time.in_time_zone.strftime("%d-%m-%Y %H:%M:%S") : "—"
  end

  def bar_width(value, max)
    max.to_i.zero? ? 0 : (value * 100.0 / max).round(1)
  end

  def restaurant_chart_rows(stats)
    stats.sales_by_restaurant.map do |row|
      {
        label: row[:label],
        value: row[:amount],
        display: "#{clp(row[:amount])} · #{pluralize(row[:count], 'orden', plural: 'órdenes')}"
      }
    end
  end

  def product_chart_rows(stats)
    stats.top_products.map do |row|
      { label: row[:label], value: row[:quantity], display: pluralize(row[:quantity], "unidad", plural: "unidades") }
    end
  end
end
