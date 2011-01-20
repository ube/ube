require "#{File.dirname(__FILE__)}/../test_helper"

class CartsTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to cart_cart_items_path, 'cart_items/index'
      jack.assert_assigns :books
      jack.assert jack.assigns(:books).empty?

      jack.adds_to_cart(:instock)
      jack.adds_to_cart(:bob_instock)

      jack.goes_to cart_cart_items_path, 'cart_items/index'
      jack.assert_assigns :books
      jack.assert_equal_with_permutation [ books(:instock), books(:bob_instock) ], jack.assigns(:books)
    end
  end

  def test_create_cart_item
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price

      jack.adds_to_cart(:bob_instock)
      jack.assert_equal_with_permutation [ books(:instock).id, books(:bob_instock).id ], jack.assigns(:cart).books
      jack.assert_equal 9, jack.assigns(:cart).total_price
    end
  end

  def test_create_cart_item_with_book_already_in_cart
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price

      jack.adds_to_cart(:instock)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price
    end
  end

  def test_create_cart_item_with_book_not_in_stock
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price

      jack.adds_to_cart(:sold)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price
    end
  end

  def test_create_cart_item_with_book_in_order
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price

      jack.adds_to_cart(:ordered)
      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price
    end
  end

  def test_destroy_cart_item
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)
      jack.adds_to_cart(:bob_instock)

      jack.assert_equal_with_permutation [ books(:instock).id, books(:bob_instock).id ], jack.assigns(:cart).books
      jack.assert_equal 9, jack.assigns(:cart).total_price

      jack.delete cart_cart_item_path(books(:instock))

      jack.assert_equal [ books(:bob_instock).id ], jack.assigns(:cart).books
      jack.assert_equal 7, jack.assigns(:cart).total_price
    end
  end

  def test_destroy_cart_item_with_book_not_in_cart
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)

      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price

      jack.delete cart_cart_item_path(books(:bob_instock))

      jack.assert_equal [ books(:instock).id ], jack.assigns(:cart).books
      jack.assert_equal 2, jack.assigns(:cart).total_price
    end
  end

  def test_destroy_cart
    new_session_as(:jack) do |jack|
      jack.adds_to_cart(:instock)

      jack.assert !jack.assigns(:cart).books.empty?
      jack.assert !jack.assigns(:cart).total_price.zero?

      jack.delete cart_path

      jack.assert jack.assigns(:cart).books.empty?
      jack.assert jack.assigns(:cart).total_price.zero?
    end
  end
end
