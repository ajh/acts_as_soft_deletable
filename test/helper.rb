require 'rubygems'

require 'test/unit'
require 'mocha'

require 'active_support'
require 'active_record'
require 'active_record/fixtures'

require File.join(File.dirname(__FILE__), '..', 'init')

begin
  # pulls from one of test/connections/#{adapter}/connection.rb depending on how rake setup our lib paths
  require 'connection' 
rescue MissingSourceFile
  # default in case our libs weren't setup
  require File.join(File.dirname(__FILE__), 'connections', 'mysql', 'connection')
end

ActiveRecord::Base.logger = Logger.new File.join(File.dirname(__FILE__),"..","tmp","test.log")

require File.join(File.dirname(__FILE__),"fixtures", "models.rb")
require File.join(File.dirname(__FILE__),"fixtures", "schema.rb")

class SoftDeleteTestCase < Test::Unit::TestCase #:nodoc:
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures  = false

  def setup
    # Some hackery to get fixtures to be refreshed before each test without transactions
    Fixtures.cache_for_connection(ActiveRecord::Base.connection).clear
    Fixtures.create_fixtures( \
      File.join(File.dirname(__FILE__), "fixtures"),
      Dir.glob('test/fixtures/*.yml').collect{|y| File.basename(y).match(%r/(.*)\.yml/)[1]}
    )
    super
  end
   
  # Found this in activesupport-2.0.2/lib/active_support/testing/default.rb.
  # It prevents this abstract testcase from running.
  def run(*args)
    #method_name appears to be a symbol on 1.8.4 and a string on 1.8.6
    return if @method_name.to_s == "default_test"
    super
  end

end
