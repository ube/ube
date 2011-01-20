require File.dirname(__FILE__) + '/../test_helper'

class BarcodeTest < ActiveSupport::TestCase
  fixtures :barcodes

  # Create

  def test_should_create_barcode
    assert_difference 'Barcode.count' do
      assert create_record.valid?
    end
  end

  # Validations

  def test_should_require_tag
    assert_presence_of_attributes Barcode, {}, :tag
  end
  def test_should_allow_valid_tag
    assert_valid_values create_record, :tag, '10'
  end
  def test_should_not_allow_invalid_tag
    assert_invalid_values create_record, :tag, 'A', '1.0', nil
  end

  def test_should_require_title
    assert_presence_of_attributes Barcode, {}, :title
  end

  def test_should_require_author
    assert_presence_of_attributes Barcode, {}, :author
  end

  # Pre- and post-sanitize

  def test_should_pre_sanitize
    initial_value = "   don'T `test` w/ this w/ test'S attr   "
    final_value   = "Don't Test With This With Test's Attr"

    assert_filter :title, initial_value, final_value
    assert_filter :author, initial_value, final_value
    assert_filter :edition, initial_value, final_value
  end

  def test_should_post_sanitize
    initial_value = "test ,   this , attr"
    final_value1  = "Test, This, Attr"
    final_value2  = "Test This Attr"

    assert_filter :title, initial_value, final_value1
    assert_filter :author, initial_value, final_value1
    assert_filter :edition, initial_value, final_value2
  end

  # Attribute sanitize

  def test_should_sanitize_author
    final_value = 'NA'
    assert_filter :author, 'unknown', final_value
    assert_filter :author, 'no author', final_value
    assert_filter :author, 'anon', final_value
    assert_filter :author, 'n/a', final_value
    assert_filter :author, 'na', final_value

    assert_filter :author, 'jack && jill', 'Jack, Jill'
    assert_filter :author, 'jack / jill', 'Jack, Jill'

    assert_filter :author, 'James Et Al', 'James et al'
    assert_filter :author, 'James Et Al.', 'James et al'
    assert_filter :author, 'James Et All', 'James et al'
    assert_filter :author, 'James Et All.', 'James et al'
  end

  def test_should_sanitize_title
    assert_filter :title, 'jack volume 1', 'Jack Vol 1'

    assert_filter :title, 'jack study guide', 'Jack STUDY GUIDE'
    assert_filter :title, 'jack study guide only', 'Jack STUDY GUIDE'
  end

  def test_should_sanitize_edition
    assert_filter :edition, 'n/a', nil
    assert_filter :edition, 'na', nil

    assert_filter :edition, 'volume 1', nil
    assert_filter :edition, 'vol 1', nil

    Barcode::EDITION_SUBST.each do |k,v|
      assert_filter :edition, "jack #{k} jill", "Jack #{v} Jill".squeeze(' ')
    end

    assert_filter :edition, '123st', '123'
    assert_filter :edition, '123nd', '123'
    assert_filter :edition, '123rd', '123'
    assert_filter :edition, '123th', '123'
  end

  # Extras

  def test_should_move_volume_from_edition_to_title
    o = create_record(:tag => '1', :title => 'jack', :author => 'jill', :edition => 'volume 1')
    o.reload
    assert_equal 'Jack Vol 1', o.title
    assert_nil o.edition

    o = create_record(:tag => '2', :title => 'jack', :author => 'jill', :edition => 'vol 1')
    o.reload
    assert_equal 'Jack Vol 1', o.title
    assert_nil o.edition
  end

protected

  def create_record(options = {})
    Barcode.create({
      :tag => '9999999999',
      :title => 'Ulysses',
      :author => 'James Joyce',
    }.merge(options))
  end
end
