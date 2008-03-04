$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
# pull in a rails projects environment.rb
require '/home/ajh/devel/substantial/gorillakiller/config/environment.rb'
require 'rubygems'
require 'active_record/fixtures'
require 'acts_as_soft_deletable'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/config.yml'))
ActiveRecord::Base.logger = Logger.new File.dirname(__FILE__) + "/debug.log"
ActiveRecord::Base.establish_connection config[ENV['DB'] || 'mysql']

require File.join(File.dirname(__FILE__),"fixtures", "models.rb")
load File.join(File.dirname(__FILE__),"fixtures", "schema.rb")

# what does these do?
#Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
#$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class Test::Unit::TestCase #:nodoc:
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  Fixtures.create_fixtures( \
    File.join(File.dirname(__FILE__), "fixtures"),
    Dir.glob('test/fixtures/*.yml').collect{|y| File.basename(y).match(%r/(.*)\.yml/)[1]}
  )
end
