require File.join(File.dirname(__FILE__), 'test_helper')

class BaseTest < Test::Unit::TestCase
  def test_destroy_creates_a_deleted_model
    artist = Artist.find_by_name('Chick Corea')
    artist.destroy
    assert_nil Artist.find_by_name('Chick Corea')

    deleted = Artist::Deleted.find_by_name('Chick Corea')
    assert_equal artist.attributes, deleted.attributes.reject{|k,v| k == 'deleted_at'}
  end
end
