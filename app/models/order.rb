class Order < ApplicationRecord
  belongs_to :restaurant
  has_many :order_items, dependent: :destroy, autosave: true, index_errors: true
  has_many :products, through: :order_items
  has_many :dispatch_attempts, dependent: :destroy

  enum :order_type, { pickup: 0, delivery: 1 }, validate: true
  enum :dispatch_status, { pending: 0, sent: 1, failed: 2 }

  before_validation :calculate_total

  validates :customer_name, presence: true
  validates :customer_phone, format: { with: /\A\+?\d{8,15}\z/ }, allow_blank: true
  validates :delivery_address, presence: true, if: :delivery?
  validates :order_items, presence: true
  validates :total_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :unique_products

  private

  def calculate_total
    order_items.each(&:assign_prices)
    self.total_amount = order_items.to_a.sum { |item| item.subtotal.to_i }
  end

  def unique_products
    product_ids = order_items.map(&:product_id)
    errors.add(:order_items, "contiene productos repetidos") if product_ids.uniq.size != product_ids.size
  end
end
