ActiveRecord::Schema.define(:version => 1) do

  create_table :artists, :force => true do |t|
    t.string :name
    t.date   :birthday
    t.string :description
    t.timestamps
  end
  Artist::Deleted.create_table(:force => true)
  
  create_table :decimals, :force => true do |t|
    t.decimal :rational_number,   :precision => 8,  :scale => 4
    t.decimal :irrational_number, :precision => 10, :scale => 8
    t.decimal :short_real_number, :precision => 5,  :scale => 2
    t.timestamps
  end
  Decimal::Deleted.create_table(:force => true)

end
