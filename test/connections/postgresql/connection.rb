puts "using postgresql"

ActiveRecord::Base.establish_connection \
  :adapter => "postgresql",
  :username => "rails",
  :password => "rails",
  :database => "acts_as_soft_deletable_plugin_test",
  :min_messages => "ERROR"
