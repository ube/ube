require "#{File.dirname(__FILE__)}/../test_helper"

class ExchangesTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication exchange_path, edit_exchange_path
    end
  end

  def test_should_deny_all_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization exchange_path, edit_exchange_path
    end
  end

  def test_should_allow_some_if_authorized
    new_session_as(:jane) do |jane|
      jane.goes_to soft_reset_exchange_path, 'exchanges/soft_reset'
      jane.goes_to hard_reset_exchange_path, 'exchanges/hard_reset'
      jane.fails_authorization exchange_path, edit_exchange_path
    end
    new_session_as(:dick) do |dick|
      dick.goes_to exchange_path, 'exchanges/show'
      dick.goes_to edit_exchange_path, 'exchanges/edit'
      dick.fails_authorization soft_reset_exchange_path, hard_reset_exchange_path
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to exchange_path, 'exchanges/show'
      jack.goes_to edit_exchange_path, 'exchanges/edit'
      jack.goes_to soft_reset_exchange_path, 'exchanges/soft_reset'
      jack.goes_to hard_reset_exchange_path, 'exchanges/hard_reset'
    end
  end

  # Actions

  def test_show
    new_session_as(:jack) do |jack|
      jack.goes_to exchange_path, 'exchanges/show'
      jack.assert_assigns :exchange
      jack.assert_equal exchanges(:dawson), jack.assigns(:exchange)
    end
  end

  def test_edit
    new_session_as(:jack) do |jack|
      jack.goes_to edit_exchange_path, 'exchanges/edit'
      jack.assert_assigns :exchange, :address
      jack.assert_equal exchanges(:dawson), jack.assigns(:exchange)
      jack.assert_equal addresses(:dawson), jack.assigns(:address)
    end
  end

  def test_update # SQLite doesn't support the CEIL function
    new_session_as(:jack) do |jack|
      assert_change exchanges(:dawson), :name, :email_address, :handling_fee, :sale_starts_on, :sale_ends_on, :reclaim_starts_on, :reclaim_ends_on, :ends_at, :hours do
        jack.put exchange_path, :exchange => valid_record
        jack.assert_flash :notice
        jack.is_redirected_to 'exchanges/show'
      end
    end
  end

  protected
    def valid_record(options = {})
      { :name => 'McGill Book Exchange', 
        :email_address => 'mcgill@example.com',
        :handling_fee => 20,
        :sale_starts_on => 2.week.ago,
        :sale_ends_on => Time.current,
        :reclaim_starts_on => Time.current,
        :reclaim_ends_on => 2.weeks.from_now,
        :ends_at => 2.weeks.from_now,
        :service_fee => 1,
        :early_reclaim_penalty => 5,
        :hours => '8am to 4pm',
      }.merge(options)
    end
end
