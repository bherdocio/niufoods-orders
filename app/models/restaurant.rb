class Restaurant < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :code, presence: true, uniqueness: true
  validates :name, :dispatch_url, presence: true
end
