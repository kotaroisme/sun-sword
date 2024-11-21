class CreateModelsAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :accounts, :created_at
    add_index :accounts, :updated_at
  end
end
