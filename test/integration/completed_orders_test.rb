require "#{File.dirname(__FILE__)}/../test_helper"

class CompletedOrdersTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication completed_orders_path, receipt_completed_order_path(orders(:completed1))
    end
  end

  def test_should_deny_all_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization completed_orders_path, receipt_completed_order_path(orders(:completed1))
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to completed_orders_path, 'completed_orders/index'
      jack.goes_to receipt_completed_order_path(orders(:completed1)), 'completed_orders/receipt'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to completed_orders_path, 'completed_orders/index'
      jack.assert_assigns :orders
      jack.assert_equal_with_permutation [ orders(:completed1), orders(:completed2) ], jack.assigns(:orders)
    end
  end

  def test_create
    new_session_as(:jack) do |jack|
      assert_change orders(:pending1), :completed_at do
        jack.put completed_order_path(orders(:pending1))

        assert books(:ordered).sold?
        assert books(:bob_ordered).sold?

        jack.assert_flash :notice
        jack.is_redirected_to 'orders/index'
      end
    end
  end

  def test_complete_and_print_receipt
    new_session_as(:jack) do |jack|
      assert_change orders(:pending1), :completed_at do
        jack.put completed_order_path(orders(:pending1), :print_receipt => 'yes')

        assert books(:ordered).sold?
        assert books(:bob_ordered).sold?

        jack.assert_no_flash :notice
        jack.is_redirected_to 'completed_orders/receipt'
      end
    end
  end

  def test_receipt
    new_session_as(:jack) do |jack|
      jack.goes_to receipt_completed_order_path(orders(:completed1)), 'completed_orders/receipt'
      jack.assert_assigns :order
      jack.assert_equal orders(:completed1), jack.assigns(:order)
    end
  end

end
