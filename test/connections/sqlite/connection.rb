puts "using sqlite"

ActiveRecord::Base.establish_connection \
  :adapter => "sqlite",
  :dbfile => "tmp/acts_as_soft_deletable_plugin.sqlite.db"
