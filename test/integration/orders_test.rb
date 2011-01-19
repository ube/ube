require "#{File.dirname(__FILE__)}/../test_helper"

class OrdersTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication orders_path
    end
  end

  def test_should_deny_some_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization orders_path
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to orders_path, 'orders/index'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to orders_path, 'orders/index'
      jack.assert_assigns :orders
      jack.assert_equal_with_permutation [ orders(:pending1), orders(:pending2) ], jack.assigns(:orders)
    end
  end

  def test_create
    new_session_as(:jack) do |jack|
      # create a cart first
      jack.adds_to_cart(:instock)
      jack.adds_to_cart(:bob_instock)

      assert_difference 'Order.count' do
        jack.post orders_path
        order = Order.last

        jack.assert_equal_with_permutation [ books(:instock), books(:bob_instock) ], order.books
        assert books(:instock).reload.ordered?
        assert books(:bob_instock).reload.ordered?

        assert jack.assigns(:cart).books.empty?
        jack.assert_flash :notice
        jack.is_redirected_to 'about/dashboard'
      end
    end
  end

  def test_destroy
    new_session_as(:jack) do |jack|
      assert_difference 'Order.count', -1 do
        jack.delete order_path(orders(:pending1))

        assert books(:ordered).instock?
        assert books(:bob_ordered).instock?

        jack.assert_flash :notice
        jack.is_redirected_to 'orders/index'
      end
    end
  end
end
