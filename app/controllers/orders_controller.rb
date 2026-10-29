class OrdersController < ApplicationController
  PER_PAGE = 25

  def index
    @restaurants = Restaurant.order(:name)
    @status_counts = Order.group(:dispatch_status).count
    @page = [ params[:page].to_i, 1 ].max

    orders = filtered_orders.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
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

  private

  def filtered_orders
    scope = Order.includes(:restaurant).order(created_at: :desc, id: :desc)
    scope = scope.where(dispatch_status: params[:status]) if Order.dispatch_statuses.key?(params[:status])
    scope = scope.where(restaurant_id: params[:restaurant_id]) if params[:restaurant_id].present?
    scope
  end
end
