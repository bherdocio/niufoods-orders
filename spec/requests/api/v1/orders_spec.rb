require "rails_helper"

RSpec.describe "API de órdenes", type: :request do
  let(:payload) do
    {
      restaurant_id: restaurants(:las_condes).id,
      order_type: "delivery",
      customer: { name: "Ana Pérez", phone: "+56912345678" },
      delivery_address: "Av. Providencia 1234, Santiago",
      items: [
        { product_id: products(:salmon_roll).id, quantity: 2 },
        { product_id: products(:gyozas).id, quantity: 1 }
      ]
    }
  end

  describe "POST /api/v1/orders" do
    it "crea la orden, calcula el total y encola el despacho" do
      expect {
        post api_v1_orders_path, params: payload.merge(total_amount: 1), as: :json
      }.to change(Order, :count).by(1).and change(OrderItem, :count).by(2)

      expect(response).to have_http_status(201)
      expect(response.parsed_body["total_amount"]).to eq(22_470)
      expect(response.parsed_body["dispatch_status"]).to eq("pending")
      expect(DispatchOrderJob.jobs.map { |job| job["args"].first }).to eq([ Order.last.id ])
    end

    it "responde 422 con los errores y no persiste nada" do
      invalid_payload = payload.merge(delivery_address: nil, items: [ { product_id: 999_999, quantity: 0 } ])

      expect {
        post api_v1_orders_path, params: invalid_payload, as: :json
      }.not_to change(Order, :count)

      expect(response).to have_http_status(422)
      expect(response.parsed_body["errors"]).to include(
        "Delivery address can't be blank",
        "Order items[0] product must exist",
        "Order items[0] quantity must be greater than 0"
      )
      expect(DispatchOrderJob.jobs).to be_empty
    end

    it "responde 400 ante un JSON mal formado" do
      post api_v1_orders_path, params: '{"restaurant_id":', headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(400)
    end
  end
end
