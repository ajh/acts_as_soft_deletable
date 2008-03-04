$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'test/unit'
# pull in a rails projects environment.rb
require '/home/ajh/devel/substantial/gorillakiller/config/environment.rb'
require 'rubygems'
require 'active_record/fixtures'
require 'mocha'

require 'acts_as_soft_deletable'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/config.yml'))
ActiveRecord::Base.logger = Logger.new File.dirname(__FILE__) + "/debug.log"
ActiveRecord::Base.establish_connection config[ENV['DB'] || 'mysql']

require File.join(File.dirname(__FILE__),"fixtures", "models.rb")
load File.join(File.dirname(__FILE__),"fixtures", "schema.rb")

# what does these do?
#Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
#$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)

class SoftDeleteTestCase < Test::Unit::TestCase #:nodoc:
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures  = false

  def setup
    Fixtures.create_fixtures( \
      File.join(File.dirname(__FILE__), "fixtures"),
      Dir.glob('test/fixtures/*.yml').collect{|y| File.basename(y).match(%r/(.*)\.yml/)[1]}
    )
    super
  end
   
  # found this in activesupport-2.0.2/lib/active_support/testing/default.rb
  # Prevents this abstrace testcase from running
  def run(*args)
    #method_name appears to be a symbol on 1.8.4 and a string on 1.8.6
    return if @method_name.to_s == "default_test"
    super
  end
end
