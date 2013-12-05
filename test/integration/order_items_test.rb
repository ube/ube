require "#{File.dirname(__FILE__)}/../test_helper"

class OrderItemsTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def test_destroy
    new_session_as(:jack) do |jack|
      jack.delete order_order_item_path(:order_id => orders(:pending1), :id => books(:ordered))

      jack.assert_equal [ books(:bob_ordered) ], orders(:pending1).books
      assert books(:ordered).reload.instock?

      jack.assert_flash :notice
      jack.is_redirected_to 'orders/index'
    end
  end
end
