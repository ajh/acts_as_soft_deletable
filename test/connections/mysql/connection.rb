puts "using mysql"

ActiveRecord::Base.establish_connection \
  :adapter => 'mysql',
  :host => 'localhost',
  :username => 'rails',
  :database => 'acts_as_soft_deletable_plugin_test'

