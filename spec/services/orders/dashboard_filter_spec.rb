require "rails_helper"

RSpec.describe Orders::DashboardFilter do
  let!(:old_order) { build_order(created_at: Time.zone.local(2026, 10, 1, 12)).tap(&:save!) }
  let!(:new_order) { build_order(restaurant: restaurants(:las_condes), created_at: Time.zone.local(2026, 10, 20, 12)).tap(&:save!) }

  it "filtra por rango de fechas incluyendo ambos extremos" do
    filter = described_class.new(from: "2026-10-20", to: "2026-10-20")

    expect(filter.base_scope).to contain_exactly(new_order)
  end

  it "invierte las fechas si vienen al revés" do
    filter = described_class.new(from: "2026-10-31", to: "2026-10-01")

    expect(filter.base_scope).to contain_exactly(old_order, new_order)
  end

  it "ignora fechas inválidas" do
    filter = described_class.new(from: "no-es-fecha")

    expect(filter.from).to be_nil
    expect(filter.base_scope).to contain_exactly(old_order, new_order)
  end

  it "filtra por tienda" do
    filter = described_class.new(restaurant_id: restaurants(:las_condes).id.to_s)

    expect(filter.base_scope).to contain_exactly(new_order)
    expect(filter.restaurants).to contain_exactly(restaurants(:las_condes))
  end

  it "aplica el estado solo al listado" do
    new_order.sent!
    filter = described_class.new(status: "sent")

    expect(filter.orders_scope).to contain_exactly(new_order)
    expect(filter.base_scope).to contain_exactly(old_order, new_order)
  end
end
