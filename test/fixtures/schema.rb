ActiveRecord::Schema.define(:version => 1) do
  create_table :artists, :force => true do |t|
    t.string :name
    t.date   :birthday
    t.string :description
    t.timestamps
  end
  Artist::Deleted.create_table(:force => true)
end
