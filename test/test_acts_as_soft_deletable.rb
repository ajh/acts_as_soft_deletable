require File.join(File.dirname(__FILE__), 'helper')

class TestActsAsSoftDeletable < SoftDeleteTestCase
  def test_destroy_should_create_a_deleted_model
    artist = Artist.find_by_name('Chick Corea')
    artist.destroy
    assert_nil Artist.find_by_name('Chick Corea')

    deleted = Artist::Deleted.find_by_name('Chick Corea')
    assert_models_equal artist, deleted
  end

  def test_deleted_model_should_be_able_to_undestroy
    assert(deleted = Artist::Deleted.find_by_name('Robert Walter'))
    assert_nil Artist.find_by_name('Robert Walter')

    deleted.undestroy!

    assert_models_equal deleted, Artist.find_by_name('Robert Walter')
    assert_nil Artist::Deleted.find_by_name('Robert Walter')
    assert deleted.frozen?
  end

  def test_should_copy_decimals_correctly
    assert_equal [1, 0], [Decimal.count, Decimal::Deleted.count]
    decimal = Decimal.find :first

    assert_difference("Decimal.count", -1) do
      assert_difference("Decimal::Deleted.count") do
        decimal.destroy
      end
    end

    assert_difference("Decimal.count") do
      assert_difference("Decimal::Deleted.count", -1) do
        deleted = Decimal::Deleted.find :first
        deleted.undestroy!
      end
    end

    restored = Decimal.find :first
    assert_models_equal decimal, restored
  end

  private

    def assert_models_equal(a, b, message = "models weren't equal")
      reject_attrs = %q(deleted_at, updated_at)
      assert_equal \
        a.attributes.reject{|k,v| reject_attrs.include? k}, 
        b.attributes.reject{|k,v| reject_attrs.include? k},
        message
    end
end
