require File.join(File.dirname(__FILE__), 'helper')

class TestTransaction < SoftDeleteTestCase
  def test_shouldnt_archive_if_destroy_fails
    artist = Artist.find_by_name('Chick Corea')
    artist.expects(:destroy_without_soft_delete).raises("some error")

    assert_raises(RuntimeError) { artist.destroy }

    assert_nil Artist::Deleted.find_by_name('Chick Corea')
    assert Artist.find_by_name('Chick Corea')
  end

  def test_shouldnt_destroy_if_archive_fails
    artist = Artist.find_by_name('Chick Corea')
    Artist::Deleted.any_instance.expects(:save!).raises("some error")

    assert_raises(RuntimeError) { artist.destroy }

    assert_nil Artist::Deleted.find_by_name('Chick Corea')
    assert Artist.find_by_name('Chick Corea')
  end
end
