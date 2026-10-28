class DispatchOrderJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  sidekiq_retries_exhausted do |job, _exception|
    Order.find_by(id: job["args"].first)&.update!(dispatch_status: :failed)
  end

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.nil? || order.sent?

    Orders::Dispatch.call(order)
  end
end
