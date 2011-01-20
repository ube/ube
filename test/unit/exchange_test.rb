require File.dirname(__FILE__) + '/../test_helper'

class ExchangeTest < ActiveSupport::TestCase
  fixtures :exchanges, :people

  # Create

  def test_should_create_exchange
    assert_difference 'Exchange.count' do
      assert create_record.valid?
    end
  end

  # Validations

  def test_should_require_name
    assert_presence_of_attributes Exchange, {}, :name
  end
  def test_should_require_unique_name
    assert_uniqueness_of_attributes Exchange, { :case_insensitive => true }, :name
  end

  def test_should_require_email_address
    assert_presence_of_attributes Exchange, {}, :email_address
  end
  def test_should_require_valid_email_address
    assert_invalid_values create_record, :email_address, 'not_valid'
  end

  def test_should_require_handling_fee
    assert_presence_of_attributes Exchange, {}, :handling_fee
  end
  def test_should_allow_valid_handling_fee
    assert_valid_values exchanges(:dawson), :handling_fee, '10', '1.0'
  end
  def test_should_not_allow_invalid_handling_fee
    assert_invalid_values exchanges(:dawson), :handling_fee, 'A', nil
  end

  def test_should_require_service_fee
    assert_presence_of_attributes Exchange, {}, :service_fee
  end
  def test_should_allow_valid_service_fee
    assert_valid_values exchanges(:dawson), :service_fee, '10'
  end
  def test_should_not_allow_invalid_service_fee
    assert_invalid_values exchanges(:dawson), :service_fee, 'A', '1.0'
  end

  def test_should_require_early_reclaim_penalty
    assert_presence_of_attributes Exchange, {}, :early_reclaim_penalty
  end
  def test_should_allow_valid_early_reclaim_penalty
    assert_valid_values exchanges(:dawson), :early_reclaim_penalty, '10'
  end
  def test_should_not_allow_invalid_early_reclaim_penalty
    assert_invalid_values exchanges(:dawson), :early_reclaim_penalty, 'A', '1.0'
  end

  def test_should_require_dates_and_hours
    assert_presence_of_attributes Exchange, {}, :sale_starts_on, :sale_ends_on, :reclaim_starts_on, :reclaim_ends_on, :ends_at, :hours
  end

  # Callbacks

  def test_should_downcase_email_address
    assert_filter :email_address, 'EXAMPLE@EXAMPLE.COM', 'example@example.com'
  end

protected

  def create_record(options = {})
    Exchange.create({
      :name => 'McGill Book Exchange',
      :email_address => 'exchange@example.com',
      :handling_fee => 10,
      :sale_starts_on => 1.week.ago,
      :sale_ends_on => 1.week.from_now,
      :reclaim_starts_on => 1.weeks.from_now,
      :reclaim_ends_on => 3.weeks.from_now,
      :ends_at => 3.weeks.from_now,
      :service_fee => 1,
      :early_reclaim_penalty => 5,
      :hours => '10am to 6pm',
    }.merge(options))
  end
end
