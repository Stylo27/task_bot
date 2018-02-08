class CreateUser < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :username, null: false
      t.integer :telegram_id, null: false
    end
  end
end
