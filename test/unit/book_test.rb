require File.dirname(__FILE__) + '/../test_helper'

class BookTest < ActiveSupport::TestCase
  fixtures :books, :barcodes, :sellers, :orders, :exchanges, :addresses

  def setup
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Create

  def test_should_create_book
    assert_difference 'Book.count' do
      assert create_record.valid?
    end
  end

  # Validations

  def test_should_require_price
    assert_presence_of_attributes Book, {}, :price
  end
  def test_should_allow_valid_price
    assert_valid_values create_record, :price, '10'
  end
  def test_should_not_allow_invalid_price
    assert_invalid_values create_record, :price, 'A', '1.0', nil
  end
  def test_should_now_allow_zero_price
    assert_invalid_values create_record, :price, '0'
  end
  def test_should_now_allow_huge_price
    assert_invalid_values create_record, :price, '1000'
  end

  def test_should_not_allow_different_price_if_ordered_or_sold_or_reclaimed
    assert_invalid_values books(:ordered), :price, '1000'
    assert_invalid_values books(:sold), :price, '1000'
    assert_invalid_values books(:book_reclaimed), :price, '1000'
  end

  def test_should_require_associations
    assert_presence_of_attributes Book, {}, :barcode_id, :seller_id
  end

  # Actions

  def test_should_calculate_sale_price
    assert_equal  1, Book.calculate_sale_price(1, 100)
    assert_equal 55, Book.calculate_sale_price(50, 10)
    assert_equal 56, Book.calculate_sale_price(50, 11)
  end

  def test_should_return_unreclaimed_books_on_unreclaimed
    assert_equal_with_permutation [ books(:instock), books(:sold), books(:lost), books(:held), books(:ordered) ], sellers(:jack).books.unreclaimed
  end

  def test_should_return_reclaimable_books_on_reclaimable
    assert_equal_with_permutation [ books(:instock), books(:sold), books(:lost), books(:held) ], sellers(:jack).books.reclaimable
  end

  def test_should_return_reclaimed_books_on_reclaimed
    assert_equal_with_permutation [ books(:book_reclaimed), books(:money_reclaimed), books(:held_reclaimed) ], sellers(:jack).books.reclaimed
  end

  def test_should_return_lost_books_on_lost_on
    assert_equal [ books(:lost) ], Book.lost_on(1.day.ago.utc.to_date)
  end

  def test_should_return_sold_books_on_sold_on
    assert_equal [ books(:sold) ], Book.sold_on(1.day.ago.utc.to_date)
  end

  # Callbacks

  def test_should_set_label_on_create
    o = create_record
    assert_equal 14, o.reload.label

    Book.destroy_all

    o = create_record
    assert_equal 1, o.reload.label
  end

  def test_should_set_sale_price_on_save
    o = create_record(:price => 20)
    assert_equal 22, o.reload.sale_price

    o = create_record(:price => 1)
    assert_equal 1, o.reload.sale_price
  end

  # Add

  def test_should_add_book
    book = create_record
    assert book.instock?
  end

  # Lost

  def test_should_lose_book
    assert books(:instock).instock?
    books(:instock).lose!
    assert_not_nil books(:instock).lost_at
    assert books(:instock).lost?
  end
  
  def test_should_find_book
    assert books(:lost).lost?
    books(:lost).stock!
    assert_nil books(:lost).lost_at
    assert books(:lost).instock?
  end

  # Held
  
  def test_should_hold_book
    assert books(:instock).instock?
    books(:instock).hold!
    assert_not_nil books(:instock).held_at
    assert books(:instock).held?
  end

  def test_should_unhold_book
    assert books(:held).held?
    books(:held).stock!
    assert_nil books(:held).held_at
    assert books(:held).instock?
  end

  # Order

  def test_should_order_book
    assert books(:instock).instock?
    books(:instock).order!
    assert books(:instock).ordered?
  end

  def test_should_restock_book
    assert books(:ordered).ordered?
    books(:ordered).stock!
    assert books(:ordered).instock?
  end

  # Sell

  def test_should_sell_book
    books(:ordered).sell!
    assert_in_delta Time.current.to_i, books(:ordered).sold_at.to_i, 1.minute
    assert books(:ordered).sold?

    response = @emails.first
    assert_equal 1, @emails.size
    assert_equal "You sold a book at ube.ca!", response.subject
    assert_equal books(:ordered).seller.email_address, response.to[0]
  end

  def test_should_not_send_email_if_no_email_address_on_sell
    books(:bob_ordered).sell!
    assert_in_delta Time.current.to_i, books(:bob_ordered).sold_at.to_i, 1.minute
    assert books(:bob_ordered).sold?

    assert_equal 0, @emails.size
  end

  def test_should_unsell_book
    books(:sold).stock!
    books(:sold).reload
    assert_nil books(:sold).sold_at
    assert_nil books(:sold).order
    assert books(:sold).instock?

    response = @emails.first
    assert_equal 1, @emails.size
    assert_equal "Your book was incorrectly marked sold at ube.ca", response.subject
    assert_equal books(:instock).seller.email_address, response.to[0]
  end

  def test_should_not_send_email_if_no_email_address_on_unsell
    books(:bob_sold).stock!
    books(:bob_sold).reload
    assert_nil books(:bob_sold).sold_at
    assert_nil books(:bob_sold).order
    assert books(:bob_sold).instock?

    assert_equal 0, @emails.size
  end

  def test_should_destroy_order_if_last_book_unsold
    books(:sold).stock!
    books(:bob_sold).stock!

    assert_raise(ActiveRecord::RecordNotFound){ orders(:completed2).reload }

    assert_nil books(:sold).reload.sold_at
    assert_nil books(:bob_sold).reload.sold_at

    assert_nil books(:sold).order
    assert_nil books(:bob_sold).order

    assert books(:sold).instock?
    assert books(:bob_sold).instock?
  end

  # Reclaim book

  def test_should_reclaim_book
    books(:instock).reclaim!
    assert_in_delta Time.current.to_i, books(:instock).reclaimed_at.to_i, 1.minute
    assert books(:instock).reclaimed?
  end

  def test_should_unreclaim_book
    books(:book_reclaimed).unreclaim!
    assert_nil books(:book_reclaimed).reclaimed_at
    assert books(:book_reclaimed).instock?

    # don't send emails for unreclaimed books
    assert_equal 0, @emails.size
  end

  # Reclaim money

  def test_should_reclaim_money
    books(:sold).reclaim!
    assert_in_delta Time.current.to_i, books(:sold).reclaimed_at.to_i, 1.minute
    assert books(:sold).reclaimed?
  end

  def test_should_unreclaim_money
    books(:money_reclaimed).unreclaim!
    assert_nil books(:money_reclaimed).reclaimed_at
    assert books(:money_reclaimed).sold?

    # don't send emails for unreclaimed money
    assert_equal 0, @emails.size
  end

  # Reclaim held
  
  def test_should_reclaim_held
    books(:held).reclaim!
    assert_in_delta Time.current.to_i, books(:held).reclaimed_at.to_i, 1.minute
    assert books(:held).reclaimed?
  end

  def test_should_unreclaim_held
    books(:held_reclaimed).unreclaim!
    assert_nil books(:held_reclaimed).reclaimed_at
    assert books(:held_reclaimed).held?

    # don't send emails for unreclaimed held
    assert_equal 0, @emails.size
  end

  # Reclaim lost

  def test_should_reclaim_lost_book
    books(:lost).reclaim!
    assert_nil books(:lost).lost_at
    assert_in_delta Time.current.to_i, books(:lost).sold_at.to_i, 1.minute
    assert_in_delta Time.current.to_i, books(:lost).reclaimed_at.to_i, 1.minute
    assert books(:lost).reclaimed?

    # don't send emails for lost books
    assert_equal 0, @emails.size
  end
  
protected

  def create_record(options = {})
    Book.create({
      :price => 20,
      :barcode_id => barcodes(:hamlet).id,
      :seller_id => sellers(:jack).id,
    }.merge(options))
  end
end
