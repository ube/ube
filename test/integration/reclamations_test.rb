require "#{File.dirname(__FILE__)}/../test_helper"

class ReclamationsTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Reclaim all

  def test_reclaim_all_with_books
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :all => true)
        jack.assert books(:instock).reload.reclaimed?
        jack.assert books(:sold).reload.reclaimed?
        jack.assert books(:lost).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Find <span>##{books(:held).label}</span> and <span>##{books(:instock).label}</span>}, jack.flash[:notice]
        jack.assert_match %r{Pay out \$#{books(:sold).price + books(:lost).price - Exchange.current.service_fee}}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_reclaim_all_with_no_books
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jill), :all => true)
        jack.assert_no_flash :notice
        jack.assert_flash :error
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  # Create

  def test_create_with_no_id
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack))
        jack.assert_no_flash :notice
        jack.assert_flash :error
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_reclaimed
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:book_reclaimed), books(:money_reclaimed) ])
        jack.assert_no_flash :notice
        jack.assert_flash :error
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_instock
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:instock))
        jack.assert books(:instock).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Find <span>##{books(:instock).label}</span>}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_sold
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:sold))
        jack.assert books(:sold).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Pay out \$#{books(:sold).price - Exchange.current.service_fee}}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_lost
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:lost))
        jack.assert books(:lost).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Pay out \$#{books(:lost).price - Exchange.current.service_fee}}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_many_id
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:instock), books(:sold), books(:lost) ])
        jack.assert books(:instock).reload.reclaimed?
        jack.assert books(:sold).reload.reclaimed?
        jack.assert books(:lost).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Find <span>##{books(:instock).label}</span>}, jack.flash[:notice]
        jack.assert_match %r{Pay out \$#{books(:sold).price + books(:lost).price - Exchange.current.service_fee}}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_create_with_reclaimed_and_unreclaimed
    with_reclaim(1.week.ago.to_date, 1.week.from_now.to_date) do
      new_session_as(:jack) do |jack|
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:instock), books(:sold), books(:lost), books(:book_reclaimed), books(:money_reclaimed) ])
        jack.assert books(:instock).reload.reclaimed?
        jack.assert books(:sold).reload.reclaimed?
        jack.assert books(:lost).reload.reclaimed?
        jack.assert_flash :notice
        jack.assert_match %r{Find <span>##{books(:instock).label}</span>}, jack.flash[:notice]
        jack.assert_match %r{Pay out \$#{books(:sold).price + books(:lost).price - Exchange.current.service_fee}}, jack.flash[:notice]
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  # Early reclaim

  def test_create_before_reclaim_with_many_books
    new_session_as(:jack) do |jack|
      jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:instock), books(:sold), books(:lost) ])
      jack.assert_match /Charged early reclaim penalty/, jack.flash[:alert]
      jack.assert_match %r{Collect \$#{3 * Exchange.current.early_reclaim_penalty + Exchange.current.service_fee - books(:sold).price - books(:lost).price}}, jack.flash[:notice]
      jack.assert_no_match %r{Pay out \$}, jack.flash[:notice]
    end
  end

  def test_create_before_reclaim_with_total_greater_than_penalty
    new_session_as(:jack) do |jack|
      jack.put seller_reclamation_path(:seller_id => sellers(:bob), :id => books(:bob_sold))
      jack.assert_match /Charged early reclaim penalty/, jack.flash[:alert]
      jack.assert_match %r{Pay out \$#{books(:bob_sold).price - Exchange.current.early_reclaim_penalty - Exchange.current.service_fee}}, jack.flash[:notice]
      jack.assert_no_match %r{Collect \$}, jack.flash[:notice]
    end
  end

  def test_create_before_reclaim_with_total_less_than_penalty
    new_session_as(:jack) do |jack|
      jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:sold))
      jack.assert_match /Charged early reclaim penalty/, jack.flash[:alert]
      jack.assert_match %r{Collect \$#{Exchange.current.early_reclaim_penalty + Exchange.current.service_fee - books(:sold).price}}, jack.flash[:notice]
      jack.assert_no_match /Pay out \$/, jack.flash[:notice]
    end
  end

  # Late reclaim

  def test_create_after_reclaim
    with_reclaim(3.weeks.ago.to_date, 1.week.ago.to_date) do
      new_session_as(:jack) do |jack|
        assert !sellers(:jack).late_reclaimer?
        jack.put seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:instock))
        assert sellers(:jack).reload.late_reclaimer?
        jack.assert_match /Marked as late reclaimer/, jack.flash[:alert]
      end
    end
  end

  # Unreclaim

  def test_destroy_with_no_id
    new_session_as(:jack) do |jack|
      jack.delete seller_reclamation_path(:seller_id => sellers(:jack))
      jack.assert_no_flash :notice
      jack.assert_flash :error
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_destroy_with_unreclaimed
    new_session_as(:jack) do |jack|
      jack.delete seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:instock), books(:sold), books(:lost) ])
      jack.assert_no_flash :notice
      jack.assert_flash :error
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_destroy_with_one_id
    new_session_as(:jack) do |jack|
      jack.delete seller_reclamation_path(:seller_id => sellers(:jack), :id => books(:book_reclaimed))
      jack.assert books(:book_reclaimed).reload.instock?
      jack.assert_flash :notice
      jack.assert_match %r{Unreclaimed ##{books(:book_reclaimed).label}}, jack.flash[:notice]
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_destroy_with_many_id
    new_session_as(:jack) do |jack|
      jack.delete seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:book_reclaimed), books(:money_reclaimed) ])
      jack.assert books(:book_reclaimed).reload.instock?
      jack.assert books(:money_reclaimed).reload.sold?
      jack.assert_flash :notice
      jack.assert_match %r{Unreclaimed}, jack.flash[:notice]
      jack.assert_match %r{##{books(:book_reclaimed).label}}, jack.flash[:notice]
      jack.assert_match %r{##{books(:money_reclaimed).label}}, jack.flash[:notice]
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_destroy_with_unreclaimed_and_reclaimed
    new_session_as(:jack) do |jack|
      jack.delete seller_reclamation_path(:seller_id => sellers(:jack), :id => [ books(:instock), books(:sold), books(:lost), books(:book_reclaimed), books(:money_reclaimed) ])
      jack.assert books(:book_reclaimed).reload.instock?
      jack.assert books(:money_reclaimed).reload.sold?
      jack.assert_flash :notice
      jack.assert_match %r{Unreclaimed}, jack.flash[:notice]
      jack.assert_match %r{##{books(:book_reclaimed).label}}, jack.flash[:notice]
      jack.assert_match %r{##{books(:money_reclaimed).label}}, jack.flash[:notice]
      jack.is_redirected_to 'sellers/show'
    end
  end
end
