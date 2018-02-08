class CreateTask < ActiveRecord::Migration[5.0]
  def change
    create_table :tasks do |t|
      t.text :description
    end
  end
end
