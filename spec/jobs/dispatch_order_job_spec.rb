require "rails_helper"

RSpec.describe DispatchOrderJob do
  it "no vuelve a despachar una orden ya enviada" do
    order = build_order(dispatch_status: :sent).tap(&:save!)

    described_class.new.perform(order.id)

    expect(a_request(:post, order.restaurant.dispatch_url)).not_to have_been_made
  end

  it "marca la orden con error al agotar los reintentos" do
    order = build_order.tap(&:save!)

    described_class.sidekiq_retries_exhausted_block.call({ "args" => [ order.id ] }, StandardError.new)

    expect(order.reload).to be_failed
  end
end
