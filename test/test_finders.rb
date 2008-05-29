require File.join(File.dirname(__FILE__), 'helper')

class TestFinders < SoftDeleteTestCase
  def test_find_with_deleted_with_all_should_return_live_and_deleted_records
    assert_equal \
      [Artist.find_by_name('Chick Corea'), Artist::Deleted.find_by_name('Robert Walter')], 
      Artist.find_with_deleted(:all)
  end

  def test_find_with_deleted_with_first_should_return_first_record
    assert_equal Artist.find_by_name('Chick Corea'), Artist.find_with_deleted(:first)
    assert_equal Artist::Deleted.find_by_name('Robert Walter'), Artist.find_with_deleted(:first, :conditions => ["name = ?", "Robert Walter"])
  end

  def test_find_with_deleted_with_ids_should_return_correct_records
    artist = Artist.find_by_name('Chick Corea')
    assert_equal artist, Artist.find_with_deleted(artist.id)

    artist.destroy
    assert_equal Artist::Deleted.find_by_name('Chick Corea'), Artist.find_with_deleted(artist.id)
  end

  def test_find_with_deleted_should_accept_options_like_find 
    assert_equal Artist::Deleted.find_by_name('Robert Walter'), Artist.find_with_deleted(:first, :conditions => ["name = :name", {:name => "Robert Walter"}])
  end

  def test_find_should_raise_with_limit_or_offset_option
    assert_raises(ArgumentError) { Artist.find_with_deleted :first, :limit => 1, :offset => 0 }
    assert_raises(ArgumentError) { Artist.find_with_deleted :first, :limit => 1, :offset => 1 }
  end

  def test_find_should_raise_with_order_option
    assert_raises(ArgumentError) { Artist.find_with_deleted(:all, :order => 'name asc') }
  end

  def test_find_all_with_deleted_dynamic_finder_should_return_correct_records
    assert_equal [Artist.find_by_name('Chick Corea')], Artist.find_all_with_deleted_by_name('Chick Corea')
    assert_equal [Artist::Deleted.find_by_name('Robert Walter')], Artist.find_all_with_deleted_by_name('Robert Walter')
  end

  def test_find_with_deleted_dynamic_finder_should_return_correct_records
    assert_equal Artist.find_by_name('Chick Corea'), Artist.find_with_deleted_by_name('Chick Corea')
    assert_equal Artist::Deleted.find_by_name('Robert Walter'), Artist.find_with_deleted_by_name('Robert Walter')
  end
end
