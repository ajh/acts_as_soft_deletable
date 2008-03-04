puts "using sqlite3"

ActiveRecord::Base.establish_connection \
  :adapter => "sqlite3",
  :dbfile => "acts_as_soft_deletable_plugin.sqlite3.db"
