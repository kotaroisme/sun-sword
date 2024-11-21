class CreateModelsUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :full_name, null: false
      t.string :role, null: false

      t.timestamps
    end
    add_index :users, :full_name
    add_index :users, :role
    add_index :users, :account_id
    add_index :users, :created_at
    add_index :users, :updated_at
  end
end
