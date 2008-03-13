class AddThing < ActiveRecord::Migration
  def self.up
    create_table("things") do |t|
      t.column :title, :text
      t.column :price, :decimal, :precision => 7, :scale => 2
      t.column :type, :string
    end
  end
  
  def self.down
    drop_table "things"
  end
end
