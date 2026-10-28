class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.integer :price, null: false
      t.timestamps

      t.check_constraint "price >= 0", name: "products_price_non_negative"
    end
    add_index :products, :sku, unique: true
  end
end
