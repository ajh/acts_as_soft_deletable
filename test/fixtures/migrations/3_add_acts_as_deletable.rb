class AddActsAsDeletable < ActiveRecord::Migration
  class Thing < ActiveRecord::Base
    acts_as_soft_deletable
  end

  def self.up
    Thing::Deleted.create_table
  end
  
  def self.down
    Thing::Deleted.drop_table
  end
end
