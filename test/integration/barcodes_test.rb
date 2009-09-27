require "#{File.dirname(__FILE__)}/../test_helper"

class BarcodesTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def setup
    Barcode.rebuild_index
  end

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication barcodes_path, edit_barcode_path(barcodes(:hamlet))
    end
  end

  def test_should_allow_all_if_authenticated
    new_session_as(:jack) do |jack|
      jack.goes_to barcodes_path, 'barcodes/index'
      jack.goes_to edit_barcode_path(barcodes(:hamlet)), 'barcodes/edit'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to barcodes_path, 'barcodes/index'
      jack.assert_assigns :barcodes
      jack.assert_select 'a.clear', false
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption', false
      jack.assert_equal_with_permutation [ barcodes(:hamlet), barcodes(:songs), barcodes(:othello), barcodes(:romeo) ], jack.assigns(:barcodes)
    end
  end

  def test_index_with_no_results
    new_session_as(:jack) do |jack|
      jack.goes_to barcodes_path(:q => 'not_valid'), 'barcodes/index'
      jack.assert_assigns :barcodes
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty'
      jack.assert_select 'caption', false
      jack.assert_equal 0, jack.assigns(:barcodes).size
    end
  end

  def test_index_with_some_results
    new_session_as(:jack) do |jack|
      jack.goes_to barcodes_path(:q => 'Shakespeare'), 'barcodes/index'
      jack.assert_assigns :barcodes
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption'
      jack.assert_equal_with_permutation [ barcodes(:hamlet), barcodes(:othello), barcodes(:romeo) ], jack.assigns(:barcodes)
    end
  end

  def test_index_with_unique_result
    new_session_as(:jack) do |jack|
      jack.get barcodes_path(:q => 'hamlet')
      jack.is_redirected_to 'barcodes/edit'
    end
  end

  def test_edit
    new_session_as(:jack) do |jack|
      jack.goes_to edit_barcode_path(barcodes(:hamlet)), 'barcodes/edit'
      jack.assert_assigns :barcode
      jack.assert_equal barcodes(:hamlet), jack.assigns(:barcode)
    end
  end

  def test_update
    new_session_as(:jack) do |jack|
      assert_change barcodes(:hamlet), :title, :author, :edition, :retail_price do
        jack.put barcode_path(barcodes(:hamlet)), :barcode => valid_record
        jack.assert_flash :notice
        jack.is_redirected_to 'barcodes/index'
      end
    end
  end

  def test_destroy_with_books
    new_session_as(:jack) do |jack|
      assert_no_difference 'Barcode.count' do
        jack.delete barcode_path(barcodes(:hamlet))
        jack.assert_flash :error
        jack.is_redirected_to 'barcodes/index'
      end
    end
  end

  def test_destroy_without_books
    new_session_as(:jack) do |jack|
      assert_difference 'Barcode.count', -1 do
        jack.delete barcode_path(barcodes(:romeo))
        jack.assert_flash :notice
        jack.is_redirected_to 'barcodes/index'
      end
    end
  end

  protected
    def valid_record(options = {})
      { :title => 'Faust', 
        :author => 'Marlowe', 
        :edition => '1', 
        :retail_price => 10, 
      }.merge(options)
    end  

end
