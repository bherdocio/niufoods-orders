class Product < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_error

  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true
  validates :price, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
