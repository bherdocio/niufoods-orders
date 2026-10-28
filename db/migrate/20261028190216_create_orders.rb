class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.integer :order_type, null: false
      t.string :customer_name, null: false
      t.string :customer_phone
      t.string :delivery_address
      t.integer :total_amount, null: false
      t.integer :dispatch_status, default: 0, null: false
      t.datetime :dispatched_at
      t.timestamps

      t.index :dispatch_status
      t.index :created_at
      t.check_constraint "total_amount >= 0", name: "orders_total_amount_non_negative"
    end
  end
end
