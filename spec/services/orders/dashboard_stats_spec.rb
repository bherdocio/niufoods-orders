require "rails_helper"

RSpec.describe Orders::DashboardStats do
  subject(:stats) { described_class.new }

  before do
    build_order(items: { products(:salmon_roll) => 2 }).save!
    build_order(restaurant: restaurants(:las_condes), items: { products(:gyozas) => 4, products(:salmon_roll) => 1 }).save!
  end

  it "suma ventas y cantidad de órdenes por tienda" do
    expect(stats.sales_by_restaurant).to eq([
      { label: "Niu Foods Las Condes", count: 1, amount: 26_950 },
      { label: "Niu Foods Providencia", count: 1, amount: 17_980 }
    ])
  end

  it "ordena los productos más vendidos por unidades" do
    expect(stats.top_products).to eq([
      { label: "Gyozas de Pollo x5", quantity: 4 },
      { label: "Niu Roll Salmón", quantity: 3 }
    ])
  end

  it "calcula las ventas totales y el ticket promedio" do
    expect(stats.total_sales).to eq(44_930)
    expect(stats.average_ticket).to eq(22_465)
  end
end
