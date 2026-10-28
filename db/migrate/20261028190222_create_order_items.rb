class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_price, null: false
      t.integer :subtotal, null: false
      t.timestamps

      t.index [ :order_id, :product_id ], unique: true
      t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    end
  end
end
