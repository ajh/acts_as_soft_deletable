class AddColumn < ActiveRecord::Migration
  class Thing < ActiveRecord::Base
    acts_as_soft_deletable
  end

  def self.up
    add_column :things, :sku, :string
    Thing::Deleted.update_columns
  end
  
  def self.down
    remove_column :things, :sku
    Thing::Deleted.update_columns
  end
end
