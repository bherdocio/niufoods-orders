class DispatchOrderJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  sidekiq_retries_exhausted do |job, _exception|
    Order.find_by(id: job["args"].first)&.update!(dispatch_status: :failed)
  end

  def self.enqueue(order)
    perform_async(order.id)
    true
  rescue RedisClient::CannotConnectError => e
    Rails.logger.error("No se pudo encolar el despacho de la orden #{order.id}: #{e.message}")
    false
  end

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.nil? || order.sent?

    Orders::Dispatch.call(order)
  end
end
