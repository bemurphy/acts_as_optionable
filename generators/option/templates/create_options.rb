class CreateOptions < ActiveRecord::Migration
  def self.up
    create_table :options do |t|
      t.string :name
      t.string :display_name
      t.string :value
      t.string :kind
      t.references :optionable, :polymorphic => true
      t.timestamps
    end
  end

  def self.down
    drop_table :options
  end
end
