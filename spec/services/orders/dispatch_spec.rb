require "rails_helper"

RSpec.describe Orders::Dispatch do
  let(:order) { build_order.tap(&:save!) }
  let(:url) { order.restaurant.dispatch_url }

  it "marca la orden como enviada cuando la tienda responde 2xx" do
    stub_request(:post, url).to_return(status: 200, body: "{}")

    described_class.call(order)

    expect(order.reload).to be_sent
    expect(order.dispatched_at).to be_present
    expect(order.dispatch_attempts.pluck(:success, :response_status)).to eq([ [ true, 200 ] ])
    expect(a_request(:post, url).with(headers: { "Idempotency-Key" => "order-#{order.id}" })).to have_been_made.once
  end

  it "marca la orden con error, sin reintentar, cuando la tienda responde 4xx" do
    stub_request(:post, url).to_return(status: 404, body: "Tienda no encontrada")

    described_class.call(order)

    expect(order.reload).to be_failed
    expect(order.dispatch_attempts.pluck(:success, :response_status)).to eq([ [ false, 404 ] ])
  end

  it "lanza un error reintentable cuando la tienda responde 5xx" do
    stub_request(:post, url).to_return(status: 503)

    expect { described_class.call(order) }.to raise_error(described_class::RetryableError)
    expect(order.reload).to be_pending
    expect(order.dispatch_attempts.pluck(:success, :response_status)).to eq([ [ false, 503 ] ])
  end

  it "lanza un error reintentable ante un timeout" do
    stub_request(:post, url).to_timeout

    expect { described_class.call(order) }.to raise_error(described_class::RetryableError)
    attempt = order.dispatch_attempts.sole
    expect(attempt.response_status).to be_nil
    expect(attempt.error_message).to include("Net::OpenTimeout")
  end
end
