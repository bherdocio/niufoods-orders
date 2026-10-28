class CreateDispatchAttempts < ActiveRecord::Migration[7.2]
  def change
    create_table :dispatch_attempts do |t|
      t.references :order, null: false, foreign_key: true
      t.boolean :success, default: false, null: false
      t.integer :response_status
      t.text :error_message

      t.timestamps
    end
  end
end
