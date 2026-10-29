require "rails_helper"

RSpec.describe Order do
  describe "cálculo del total" do
    it "usa los precios de la base e ignora el total enviado por el cliente" do
      order = build_order(items: { products(:salmon_roll) => 2, products(:gyozas) => 1 }, total_amount: 1)

      expect(order.save).to be(true)
      expect(order.total_amount).to eq(22_470)
      expect(order.order_items.map(&:unit_price)).to eq([ 8990, 4490 ])
    end

    it "mantiene el precio original aunque el producto cambie y la orden se actualice" do
      order = build_order.tap(&:save!)
      products(:salmon_roll).update!(price: 9990)

      order.reload.update!(dispatch_status: :sent)

      expect(order.order_items.first.reload.unit_price).to eq(8990)
      expect(order.reload.total_amount).to eq(17_980)
    end
  end

  describe "validaciones" do
    it "exige dirección para delivery" do
      order = build_order(order_type: "delivery")

      expect(order).not_to be_valid
      expect(order.errors[:delivery_address]).to include("can't be blank")
    end

    it "rechaza un tipo de orden inválido sin lanzar excepción" do
      order = build_order(order_type: "otro")

      expect(order).not_to be_valid
      expect(order.errors[:order_type]).to be_present
    end

    it "exige al menos un producto" do
      order = build_order(items: {})

      expect(order).not_to be_valid
      expect(order.errors[:order_items]).to be_present
    end

    it "rechaza productos repetidos en la misma orden" do
      order = build_order
      order.order_items.build(product: products(:salmon_roll), quantity: 1)

      expect(order).not_to be_valid
      expect(order.errors[:order_items]).to include("contiene productos repetidos")
    end

    it "rechaza cantidades no positivas" do
      order = build_order(items: { products(:salmon_roll) => 0 })

      expect(order).not_to be_valid
      expect(order.errors.attribute_names).to include(:"order_items[0].quantity")
    end
  end
end
