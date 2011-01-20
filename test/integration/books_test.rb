require "#{File.dirname(__FILE__)}/../test_helper"

class BooksTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def setup
    Book.rebuild_index
  end

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication books_path, all_books_path, new_seller_book_path(:seller_id => sellers(:jack)), edit_seller_book_path(:seller_id => sellers(:jack), :id => books(:instock))
    end
  end

  def test_should_deny_some_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization all_books_path
    end
  end

  def test_should_allow_some_if_authenticated
    new_session_as(:joe) do |joe|
      joe.goes_to books_path, 'books/index'
      joe.goes_to new_seller_book_path(:seller_id => sellers(:jack)), 'books/new'
      joe.goes_to edit_seller_book_path(:seller_id => sellers(:jack), :id => books(:instock)), 'books/edit'
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to books_path, 'books/index'
      jack.goes_to all_books_path, 'books/all'
      jack.goes_to new_seller_book_path(:seller_id => sellers(:jack)), 'books/new'
      jack.goes_to edit_seller_book_path(:seller_id => sellers(:jack), :id => books(:instock)), 'books/edit'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to books_path, 'books/index'
      jack.assert_not_assigns :books
      jack.assert_select 'a.clear', false
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption', false
    end
  end

  def test_index_with_no_results
    new_session_as(:jack) do |jack|
      jack.goes_to books_path(:q => 'not_valid'), 'books/index'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty'
      jack.assert_select 'caption', false
      jack.assert_equal 0, jack.assigns(:books).size
    end
  end

  def test_index_with_some_results
    new_session_as(:jack) do |jack|
      jack.goes_to books_path(:q => 'Shakespeare'), 'books/index'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption'
      jack.assert_equal_with_permutation [ books(:instock), books(:bob_instock) ], jack.assigns(:books)
    end
  end

  def test_all
    new_session_as(:jack) do |jack|
      jack.goes_to all_books_path, 'books/all'
      jack.assert_not_assigns :books
      jack.assert_select 'a.clear', false
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption', false
    end
  end

  def test_all_with_no_results
    new_session_as(:jack) do |jack|
      jack.goes_to all_books_path(:q => 'not_valid'), 'books/all'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty'
      jack.assert_select 'caption', false
      jack.assert_equal 0, jack.assigns(:books).size
    end
  end

  def test_all_with_some_results
    new_session_as(:jack) do |jack|
      jack.goes_to all_books_path(:q => 'Shakespeare'), 'books/all'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption'
      jack.assert_equal_with_permutation [ books(:instock), books(:sold), books(:book_reclaimed), books(:money_reclaimed), books(:held_reclaimed), books(:lost), books(:held), books(:bob_instock), books(:bob_sold), books(:ordered), books(:bob_ordered) ], jack.assigns(:books)
    end
  end

  def test_new
    new_session_as(:jack) do |jack|
      jack.goes_to new_seller_book_path(:seller_id => sellers(:jack)), 'books/new'
      jack.assert_assigns :book, :seller, :barcode
    end
  end

  def test_create_with_old_barcode
    new_session_as(:jack) do |jack|
      assert_difference 'Book.count' do
        assert_no_difference 'Barcode.count' do
          assert_no_change barcodes(:hamlet), :title, :author, :edition, :retail_price do
            jack.post seller_books_path(:seller_id => sellers(:jack)), :book => valid_book, :barcode => valid_barcode(:tag => barcodes(:hamlet).tag)
            jack.assert_flash :notice
            jack.is_redirected_to 'sellers/show'
          end
        end
      end
    end
  end

  def test_create_with_new_barcode
    new_session_as(:jack) do |jack|
      assert_difference 'Book.count' do
        assert_difference 'Barcode.count' do
          jack.post seller_books_path(:seller_id => sellers(:jack)), :book => valid_book, :barcode => valid_barcode
          jack.assert_flash :notice
          jack.is_redirected_to 'sellers/show'
        end
      end
    end
  end

  def test_create_and_add_another
    new_session_as(:jack) do |jack|
      jack.post seller_books_path(:seller_id => sellers(:jack)), :book => valid_book, :barcode => valid_barcode(:tag => barcodes(:hamlet).tag), :add_a_book => 'yes'
      jack.assert_flash :notice
      jack.is_redirected_to 'books/new'
    end
  end

  def test_create_and_print_a_contract
    new_session_as(:jack) do |jack|
      jack.post seller_books_path(:seller_id => sellers(:jack)), :book => valid_book, :barcode => valid_barcode(:tag => barcodes(:hamlet).tag), :print_a_contract => 'yes'
      jack.assert_flash :notice
      jack.is_redirected_to 'sellers/contract'
    end
  end

  def test_edit
    new_session_as(:jack) do |jack|
      jack.goes_to edit_seller_book_path(:seller_id => sellers(:jack), :id => books(:instock)), 'books/edit'
      jack.assert_assigns :book, :seller, :barcode
      jack.assert_equal books(:instock), jack.assigns(:book)
      jack.assert_equal sellers(:jack), jack.assigns(:seller)
      jack.assert_equal barcodes(:hamlet), jack.assigns(:barcode)
    end
  end

  def test_update_with_old_barcode
    new_session_as(:jack) do |jack|
      assert_change books(:instock), :price, :cdrom, :study_guide, :package, :access_code, :barcode do
        assert_no_difference 'Barcode.count' do
          assert_no_change barcodes(:songs), :title, :author, :edition, :retail_price do
            jack.put seller_book_path(:seller_id => sellers(:jack), :id => books(:instock)), :book => valid_book, :barcode => valid_barcode(:tag => barcodes(:songs).tag)
            jack.assert_flash :notice
            jack.is_redirected_to 'sellers/show'
          end
        end
      end
    end
  end

  def test_update_with_new_barcode
    new_session_as(:jack) do |jack|
      assert_change books(:instock), :price, :cdrom, :study_guide, :package, :access_code, :barcode do
        assert_difference 'Barcode.count' do
          jack.put seller_book_path(:seller_id => sellers(:jack), :id => books(:instock)), :book => valid_book, :barcode => valid_barcode
          jack.assert_flash :notice
          jack.is_redirected_to 'sellers/show'
        end
      end
    end
  end

  def test_destroy
    new_session_as(:jack) do |jack|
      assert_difference 'Book.count', -1 do
        jack.delete seller_book_path(:seller_id => sellers(:jack), :id => books(:instock))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

protected

  def valid_book(options = {})
    { :price => '9',
      :cdrom => '1',
      :study_guide => '1',
      :package => '1',
      :access_code => '1',
    }.merge(options)
  end

  def valid_barcode(options = {})
    { :tag => '9',
      :title => 'Faust',
      :author => 'Marlowe',
      :edition => '1',
      :retail_price => 10,
    }.merge(options)
  end
end
