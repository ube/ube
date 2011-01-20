require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < ActiveSupport::TestCase
  fixtures :orders, :books, :exchanges, :addresses

  # Create

  def test_should_create_order
    assert_difference 'Order.count' do
      assert create_record.valid?
    end
  end

  # Actions

  def test_should_fill_order_on_full
    order = create_record
    order.fill!  [ books(:instock), books(:bob_instock) ]
    assert_equal [ books(:instock), books(:bob_instock) ], order.books
    assert books(:instock).ordered?
    assert books(:bob_instock).ordered?
  end

  def test_should_complete_order_on_complete
    assert books(:ordered).ordered?
    assert books(:bob_ordered).ordered?

    assert orders(:pending1).complete!
    assert_in_delta Time.current.to_i, orders(:pending1).completed_at.to_i, 1.minute

    assert books(:ordered).reload.sold?
    assert books(:bob_ordered).reload.sold?
  end

  def test_should_reset_order_on_books_on_destroy
    assert books(:ordered).ordered?
    assert books(:bob_ordered).ordered?
    assert_equal orders(:pending1), books(:ordered).order
    assert_equal orders(:pending1), books(:bob_ordered).order

    orders(:pending1).destroy

    assert books(:ordered).reload.instock?
    assert books(:bob_ordered).reload.instock?
    assert_nil books(:ordered).order
    assert_nil books(:bob_ordered).order
  end

  def test_should_remove_book_on_remove_book
    assert_equal orders(:pending1), books(:ordered).order
    assert_equal orders(:pending1), books(:bob_ordered).order

    orders(:pending1).remove_book(books(:ordered))

    assert_nil books(:ordered).reload.order
    assert_equal orders(:pending1), books(:bob_ordered).reload.order
  end

  def test_should_destroy_order_if_last_book_removed
    assert_equal orders(:pending1), books(:ordered).order
    assert_equal orders(:pending1), books(:bob_ordered).order

    orders(:pending1).remove_book(books(:ordered))
    orders(:pending1).remove_book(books(:bob_ordered))
    assert_raise(ActiveRecord::RecordNotFound){ orders(:pending1).reload }

    assert_nil books(:ordered).reload.order
    assert_nil books(:bob_ordered).reload.order
  end

  def test_should_calculate_total_on_total
    assert_equal 19, orders(:pending1).total
  end

protected

  def create_record(options = {})
    Order.create(options)
  end
end
