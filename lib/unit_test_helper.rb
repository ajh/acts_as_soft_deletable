module Test #:nodoc:
  module Unit #:nodoc:
    # This module is included into Test::Unit::TestCase and in that way is available in your test cases.
    module ActsAsDeleted
      # Takes a saved model and runs assertions testing whether soft deleting is working.
      def assert_model_soft_deletes(model) # TODO: should accept a message argument
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
   
      # Asserts whether a two soft deleting models are equal. Intended to be passed
      # an instance of a model and an instance of the deleted class's model (in any order). Checks that
      # all attributes were saved off correctly.
      def assert_soft_delete_models_are_equal(a, b, message = "models weren't equal")
        reject_attrs = %q(deleted_at, updated_at)
        assert_equal \
          a.attributes.reject{|k,v| reject_attrs.include? k}, 
          b.attributes.reject{|k,v| reject_attrs.include? k},
          message
      end
    end
  end
end

Test::Unit::TestCase.send(:include, Test::Unit::ActsAsDeleted)
