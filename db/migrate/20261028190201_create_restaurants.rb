class CreateRestaurants < ActiveRecord::Migration[7.2]
  def change
    create_table :restaurants do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :dispatch_url, null: false
      t.timestamps
    end
    add_index :restaurants, :code, unique: true
  end
end
