require "#{File.dirname(__FILE__)}/../test_helper"

class SoldBooksTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def setup
    Book.rebuild_index
  end

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication sold_books_path
    end
  end

  def test_should_deny_all_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization sold_books_path
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to sold_books_path, 'sold_books/index'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to sold_books_path, 'sold_books/index'
      jack.assert_not_assigns :books
      jack.assert_select 'a.clear', false
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption', false
    end
  end

  def test_index_with_no_results
    new_session_as(:jack) do |jack|
      jack.goes_to sold_books_path(:q => 'not_valid'), 'sold_books/index'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty'
      jack.assert_select 'caption', false
      jack.assert_equal 0, jack.assigns(:books).size
    end
  end

  def test_index_with_some_results
    new_session_as(:jack) do |jack|
      jack.goes_to sold_books_path(:q => 'Shakespeare'), 'sold_books/index'
      jack.assert_assigns :books
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption'
      jack.assert_equal_with_permutation [ books(:sold), books(:bob_sold) ], jack.assigns(:books)
    end
  end

  def test_destroy
    new_session_as(:jack) do |jack|
      jack.delete sold_book_path(books(:sold))
      jack.assert books(:sold).reload.instock?
    end
  end
end
