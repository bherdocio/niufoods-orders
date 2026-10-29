class OrdersController < ApplicationController
  PER_PAGE = 25

  def index
    @filter = Orders::DashboardFilter.new(params)
    @restaurants = Restaurant.order(:name)
    @stats = Orders::DashboardStats.new(@filter.base_scope, @filter.restaurants, from: @filter.from, to: @filter.to)
    @status_counts = @stats.status_counts
    @page = [ params[:page].to_i, 1 ].max

    orders = @filter.orders_scope
                    .includes(:restaurant)
                    .order(created_at: :desc, id: :desc)
                    .offset((@page - 1) * PER_PAGE)
                    .limit(PER_PAGE + 1)
                    .to_a
    @next_page = orders.size > PER_PAGE
    @orders = orders.first(PER_PAGE)
  end

  def show
    @order = Order.includes(:restaurant, order_items: :product).find(params[:id])
    @attempts = @order.dispatch_attempts.order(:created_at)
  end

  def redispatch
    order = Order.find(params[:id])

    unless order.failed?
      return redirect_to order_path(order), alert: "Solo se pueden reintentar órdenes con error"
    end

    order.update!(dispatch_status: :pending)

    if DispatchOrderJob.enqueue(order)
      redirect_to order_path(order), notice: "Orden ##{order.id} reencolada para despacho"
    else
      order.update!(dispatch_status: :failed)
      redirect_to order_path(order), alert: "No se pudo encolar el despacho. Revisa que Redis esté disponible."
    end
  end
end
