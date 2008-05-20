require File.join(File.dirname(__FILE__), 'helper')

if ActiveRecord::Base.connection.supports_migrations? 
  class Thing < ActiveRecord::Base
    acts_as_soft_deletable
  end

  class TestMigration < SoftDeleteTestCase

    # a santiy check 
    def test_that_i_can_do_a_migration_from_this_test_case
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }

      migrate_up(3)

      t = Thing.create! :title => 'blah blah', :price => 123.45, :type => 'Thing'
      assert_model_soft_deletes(t)

      migrate_down

      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
      assert_raises(ActiveRecord::StatementInvalid) { Thing::Deleted.find_by_title('blah blah') }
    end

    def test_should_create_deleted_table
      migrate_up(2)
      assert_raises(ActiveRecord::StatementInvalid) { Thing::Deleted.find_by_title('blah blah') }

      migrate_up(3)
      t = Thing.create! :title => 'blah blah', :price => 123.45, :type => 'Thing'
      assert_model_soft_deletes(t)
    end

    def test_should_help_when_adding_columns
      migrate_up(4)
      t = Thing.create! :title => 'blah blah', :price => 123.45, :type => 'Thing', :sku => 'XYZ123abc'
      assert_model_soft_deletes(t)
    end

    def test_should_help_when_removing_columns_and_warn
      migrate_up(4)

      stderr = run_and_capture_stderr do
        migrate_up(5)
      end

      assert_match %r/removing column deleted_things.sku/, stderr
    end

    def test_should_be_able_to_supress_warning_when_removing_columns
      migrate_up(4)

      stderr = run_and_capture_stderr do
        ActiveRecord::Acts::SoftDeletable.remove_column_warning_enabled = false
        migrate_up(5)
      end

      assert_equal "", stderr
    ensure
      ActiveRecord::Acts::SoftDeletable.remove_column_warning_enabled = true
    end

    def teardown
      migrate_down
    rescue ActiveRecord::StatementInvalid
      # force attempting to leave test db in a good state
      Thing.connection.drop_table "things" rescue nil
      Thing.connection.drop_table "deleted_things" rescue nil

      #ActiveRecord::Base.connection.initialize_schema_information
      ActiveRecord::Base.connection.update "UPDATE schema_info SET version = 1"
    ensure
      Thing.reset_column_information
      Thing::Deleted.reset_column_information
    end
        
    private

      def migrate_up(version=nil)
        ActiveRecord::Migrator.up(File.dirname(__FILE__) + '/fixtures/migrations/', version)
      end

      def migrate_down(version=nil)
        ActiveRecord::Migrator.down(File.dirname(__FILE__) + '/fixtures/migrations/', version)
      end

      # takes a saved model and runs assertions testing whether soft deleting is working
      def assert_model_soft_deletes(model)
        klass = model.class
        deleted_klass = model.class.deleted_class

        assert_raises(ActiveRecord::RecordNotFound) { deleted_klass.find model.id }
        model.destroy

        assert(deleted = deleted_klass.find(model.id))
        assert_raises(ActiveRecord::RecordNotFound) { klass.find model.id }

        deleted.undestroy!

        assert_soft_delete_models_are_equal deleted, klass.find(model.id)
        assert_raises(ActiveRecord::RecordNotFound) { deleted_klass.find model.id }
      end

      def run_and_capture_stderr
        io = StringIO.new '', 'w+'
        $stderr = io

        yield

        io.rewind
        return io.read
      ensure
        $stderr = STDERR
      end
  end
end


