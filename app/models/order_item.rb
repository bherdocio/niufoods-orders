class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  before_validation :assign_prices, on: :create

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :subtotal, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :product_id, uniqueness: { scope: :order_id }

  def assign_prices
    return unless product && quantity

    self.unit_price = product.price
    self.subtotal = unit_price * quantity
  end
end
