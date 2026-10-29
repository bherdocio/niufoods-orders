require "rails_helper"

RSpec.describe Orders::DashboardStats do
  subject(:stats) { described_class.new(Order.all, Restaurant.order(:name)) }

  let!(:providencia_order) { build_order(items: { products(:salmon_roll) => 2 }).tap(&:save!) }
  let!(:las_condes_order) do
    build_order(restaurant: restaurants(:las_condes), items: { products(:gyozas) => 4, products(:salmon_roll) => 1 }).tap(&:save!)
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

  it "cuenta las órdenes por estado de despacho" do
    las_condes_order.sent!

    expect(stats.status_counts).to eq("pending" => 1, "sent" => 1)
  end

  describe "#sales_over_time" do
    it "agrupa por hora y completa con cero cuando el período es de hasta 24 horas" do
      providencia_order.update_columns(created_at: Time.zone.local(2026, 10, 29, 10, 15))
      las_condes_order.update_columns(created_at: Time.zone.local(2026, 10, 29, 12, 40))

      expect(stats.sales_over_time).to eq([
        { label: "10:00", value: 17_980 },
        { label: "11:00", value: 0 },
        { label: "12:00", value: 26_950 }
      ])
    end

    it "agrupa por día cuando el período supera 24 horas" do
      providencia_order.update_columns(created_at: Time.zone.local(2026, 10, 1, 10))
      las_condes_order.update_columns(created_at: Time.zone.local(2026, 10, 3, 18))

      expect(stats.sales_over_time).to eq([
        { label: "01-10", value: 17_980 },
        { label: "02-10", value: 0 },
        { label: "03-10", value: 26_950 }
      ])
    end

    it "usa el rango del filtro y completa con cero los días sin ventas" do
      providencia_order.update_columns(created_at: Time.zone.local(2026, 10, 2, 10))
      las_condes_order.update_columns(created_at: Time.zone.local(2026, 10, 2, 12))
      ranged_stats = described_class.new(Order.all, Restaurant.order(:name), from: Date.new(2026, 10, 1), to: Date.new(2026, 10, 3))

      expect(ranged_stats.sales_over_time).to eq([
        { label: "01-10", value: 0 },
        { label: "02-10", value: 44_930 },
        { label: "03-10", value: 0 }
      ])
    end
  end
end
