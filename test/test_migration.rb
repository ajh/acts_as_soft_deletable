require File.join(File.dirname(__FILE__), 'helper')

if ActiveRecord::Base.connection.supports_migrations? 
  class Thing < ActiveRecord::Base
    acts_as_soft_deletable
  end

  class TestMigration < SoftDeleteTestCase

    def test_should_create_deleted_table
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }

      migrate_up(3)

      assert_soft_delete_works

      migrate_down

      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
      assert_raises(ActiveRecord::StatementInvalid) { Thing::Deleted.find_by_title('blah blah') }
    end

    def test_should_help_when_adding_columns
      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }

      migrate_up(4)

      #t = Thing.create! :title => 'blah blah', :price => 123.45, :type => 'Thing'
      #new_assert_soft_delete_works(t)
      assert_soft_delete_works

      migrate_down

      assert_raises(ActiveRecord::StatementInvalid) { Thing.create :title => 'blah blah' }
      assert_raises(ActiveRecord::StatementInvalid) { Thing::Deleted.find_by_title('blah blah') }
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
      def new_assert_soft_delete_works(model)
        klass = model.class
        deleted_klass = model.class.deleted_class

        assert_raises(ActiveRecord::RecordNotFound) { deleted_klass.find model.id }
        model.destroy

        assert(deleted = deleted_klass.find(model.id))
        assert_raises(ActiveRecord::RecordNotFound) { klass.find model.id }

        deleted.undestroy!

        assert_models_equal deleted, klass.find(model.id)
        assert_raises(ActiveRecord::RecordNotFound) { deleted_klass.find model.id }
      end

      def assert_soft_delete_works
        t = Thing.create! :title => 'blah blah', :price => 123.45, :type => 'Thing'

        assert_nil Thing::Deleted.find_by_title('blah blah')
        t.destroy

        assert(deleted = Thing::Deleted.find_by_title('blah blah'))
        assert_nil Thing.find_by_title('blah blah')

        deleted.undestroy!

        assert_models_equal deleted, Thing.find_by_title('blah blah')
        assert_nil Thing::Deleted.find_by_title('blah blah')
      end
  end
end
