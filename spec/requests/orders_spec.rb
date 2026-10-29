require "rails_helper"

RSpec.describe "Dashboard de órdenes", type: :request do
  let!(:order) { build_order.tap(&:save!) }
  let(:order_link) { %(href="#{order_path(order)}") }

  it "lista las órdenes" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(order_link)
  end

  it "filtra por estado de despacho" do
    get orders_path(status: "sent")

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(order_link)
  end

  it "muestra el detalle de la orden" do
    get order_path(order)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Orden ##{order.id}")
  end

  it "reencola el despacho de una orden con error" do
    order.failed!

    post redispatch_order_path(order)

    expect(response).to redirect_to(order_path(order))
    expect(order.reload).to be_pending
    expect(DispatchOrderJob.jobs.map { |job| job["args"].first }).to eq([ order.id ])
  end

  it "no reencola órdenes que no tienen error" do
    post redispatch_order_path(order)

    expect(response).to redirect_to(order_path(order))
    expect(DispatchOrderJob.jobs).to be_empty
  end

  it "muestra los indicadores y gráficos de ventas" do
    get root_path

    expect(response.body).to include("Ventas por tienda", "Productos más vendidos", "Ticket promedio")
  end
end
