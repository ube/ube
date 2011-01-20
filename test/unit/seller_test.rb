require File.dirname(__FILE__) + '/../test_helper'

class SellerTest < ActiveSupport::TestCase
  fixtures :books, :exchanges, :sellers

  def setup
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Create

  def test_should_create_seller
    assert_difference 'Seller.count' do
      assert create_record.valid?
    end
  end

  # Validations

  def test_should_require_name
    assert_presence_of_attributes Seller, {}, :name
  end

  def test_should_require_telephone_without_letters
    assert_invalid_values create_record, :telephone, '1800notvalid'
  end

  def test_should_require_valid_email_address
    assert_invalid_values create_record, :email_address, 'not_valid'
  end
  def test_should_require_unique_email_address
    assert_uniqueness_of_attributes Seller, { :case_insensitive => true }, :email_address
  end

  # Actions

  def test_should_set_contract_printed_at_on_print_contract
    assert sellers(:jack).print_contract!
    assert_in_delta Time.current.to_i, sellers(:jack).contract_printed_at.to_i, 1.minute
  end



  def test_should_send_welcome_email_if_not_sent
    assert !sellers(:jack).welcome_email_sent_at?
    assert sellers(:jack).send_welcome_email!
    assert_in_delta Time.current.to_i, sellers(:jack).welcome_email_sent_at.to_i, 1.minute
    assert sellers(:jack).welcome_email_sent_at?

    response = @emails.first
    assert_equal 1, @emails.size
    assert_equal "Welcome to the Dawson Book Exchange!", response.subject
    assert_equal sellers(:jack).email_address, response.to[0]
  end

  def test_should_not_send_welcome_email_if_sent
    assert sellers(:jill).welcome_email_sent_at?
    assert_nil sellers(:jill).send_welcome_email!
    assert_in_delta 1.day.ago.to_i, sellers(:jill).welcome_email_sent_at.to_i, 1.minute
    assert sellers(:jill).welcome_email_sent_at?

    assert_equal 0, @emails.size
  end

  def test_should_not_send_welcome_email_if_no_email_address
    assert !sellers(:bob).welcome_email_sent_at?
    assert_nil sellers(:bob).send_welcome_email!
    assert !sellers(:bob).welcome_email_sent_at?

    assert_equal 0, @emails.size
  end



  def test_should_pay_service_fee_if_not_paid
    assert !sellers(:jack).paid_service_fee_at?
    assert sellers(:jack).pay_service_fee!
    assert_in_delta Time.current.to_i, sellers(:jack).paid_service_fee_at.to_i, 1.minute
    assert sellers(:jack).paid_service_fee_at?
  end

  def test_should_not_pay_service_fee_if_paid
    assert sellers(:jill).paid_service_fee_at?
    assert_nil sellers(:jill).pay_service_fee!
    assert_in_delta 1.day.ago.to_i, sellers(:jill).paid_service_fee_at.to_i, 1.minute
    assert sellers(:jill).paid_service_fee_at?
  end

  def test_should_unpay_service_fee_if_paid
    assert sellers(:jill).paid_service_fee_at?
    assert sellers(:jill).unpay_service_fee!
    assert_nil sellers(:jill).paid_service_fee_at
    assert !sellers(:jill).paid_service_fee_at?
  end

  def test_should_not_unpay_service_fee_if_not_paid
    assert !sellers(:jack).paid_service_fee_at?
    assert_nil sellers(:jack).unpay_service_fee!
    assert_nil sellers(:jack).paid_service_fee_at
    assert !sellers(:jack).paid_service_fee_at?
  end



  def test_should_mark_late_reclaimer
    assert !sellers(:jack).late_reclaimer?
    assert sellers(:jack).late_reclaimer!
    assert_equal Date.current, sellers(:jack).late_reclaimer_on
    assert sellers(:jack).late_reclaimer?
  end



  def test_should_reclaim
    with_reclaim(1.week.ago, 1.week.from_now) do
      assert !sellers(:jack).late_reclaimer?
      assert !sellers(:jack).paid_service_fee_at?
      assert_equal sellers(:jack).reclaim!, 6
      assert_in_delta Time.current.to_i, sellers(:jack).paid_service_fee_at.to_i, 1.minute
      assert sellers(:jack).paid_service_fee_at?
      assert !sellers(:jack).late_reclaimer?

      assert books(:instock).reload.reclaimed?
      assert books(:sold).reload.reclaimed?
      assert books(:lost).reload.reclaimed?
    end
  end

  def test_should_reclaim_with_one_book
    with_reclaim(1.week.ago, 1.week.from_now) do
      assert !sellers(:jack).paid_service_fee_at?
      assert_equal sellers(:jack).reclaim!([ books(:instock) ]), -1
      assert sellers(:jack).paid_service_fee_at?

      assert books(:instock).reload.reclaimed?
      assert !books(:sold).reload.reclaimed?
      assert !books(:lost).reload.reclaimed?
    end
  end

  def test_should_reclaim_with_service_fee
    with_reclaim(1.week.ago, 1.week.from_now) do
      assert sellers(:jill).paid_service_fee_at?
      assert_equal sellers(:jill).reclaim!, 0
      assert_in_delta 1.day.ago.to_i, sellers(:jill).paid_service_fee_at.to_i, 1.minute
      assert sellers(:jill).paid_service_fee_at?
    end
  end

  def test_should_reclaim_without_service_fee
    with_reclaim(1.week.ago, 1.week.from_now) do
      assert !sellers(:jack).paid_service_fee_at?
      assert_equal sellers(:jack).reclaim!, 6
      assert_in_delta Time.current.to_i, sellers(:jack).paid_service_fee_at.to_i, 1.minute
      assert sellers(:jack).paid_service_fee_at?
    end
  end

  def test_should_reclaim_with_early_reclaim
    with_reclaim(1.week.from_now, 3.weeks.from_now) do
      assert !sellers(:jack).late_reclaimer?
      assert_equal sellers(:jack).reclaim!, -14
      assert !sellers(:jack).late_reclaimer?
    end
  end

  def test_should_reclaim_with_late_reclaim
    with_reclaim(3.weeks.ago, 1.week.ago) do
      assert !sellers(:jack).late_reclaimer?
      assert_equal sellers(:jack).reclaim!, 6
      assert sellers(:jack).late_reclaimer?
    end
  end



  def test_should_send_welcome_back_if_not_sent
    assert !sellers(:jack).welcome_back_sent_on?
    assert sellers(:jack).send_welcome_back!
    assert_equal Date.current, sellers(:jack).welcome_back_sent_on
    assert sellers(:jack).welcome_back_sent_on?
  end

  def test_should_not_send_welcome_back_if_sent
    assert sellers(:jill).welcome_back_sent_on?
    assert_nil sellers(:jill).send_welcome_back!
    assert_equal Date.yesterday, sellers(:jill).welcome_back_sent_on
    assert sellers(:jill).welcome_back_sent_on?
  end



  def test_should_send_reclaim_reminder_if_not_sent
    assert !sellers(:jack).reclaim_reminder_sent_on?
    assert sellers(:jack).send_reclaim_reminder!
    assert_equal Date.current, sellers(:jack).reclaim_reminder_sent_on
    assert sellers(:jack).reclaim_reminder_sent_on?
  end

  def test_should_not_send_reclaim_reminder_if_sent
    assert sellers(:jill).reclaim_reminder_sent_on?
    assert_nil sellers(:jill).send_reclaim_reminder!
    assert_equal Date.yesterday, sellers(:jill).reclaim_reminder_sent_on
    assert sellers(:jill).reclaim_reminder_sent_on?
  end

  # Callbacks

  def test_should_not_destroy_with_books
    assert_no_difference 'Seller.count' do
      assert_false sellers(:jack).destroy
    end
  end
  def test_should_destroy_without_books
    assert_difference 'Seller.count', -1 do
      assert sellers(:jill).destroy
    end
  end

  def test_should_titleize_name
    assert_filter :name, 'james mckinney', 'James Mckinney'
  end
  def test_should_sanitize_telephone
    assert_filter :telephone, '1-800-555-5555', '18005555555'
  end
  def test_should_downcase_email_address
    assert_filter :email_address, 'EXAMPLE@EXAMPLE.COM', 'example@example.com'
  end

protected

  def create_record(options = {})
    Seller.create({ :name => 'James McKinney' }.merge(options))
  end
end
