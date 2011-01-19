require "#{File.dirname(__FILE__)}/../test_helper"

class ReportsTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication url_for({ :controller => 'reports', :action => 'summary' }), url_for({ :controller => 'reports', :action => 'outstanding' }), url_for({ :controller => 'reports', :action => 'emails' })
    end
  end

  def test_should_deny_all_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization url_for({ :controller => 'reports', :action => 'summary' }), url_for({ :controller => 'reports', :action => 'outstanding' }), url_for({ :controller => 'reports', :action => 'emails' })
    end
  end

  def test_should_allow_some_if_authorized
    new_session_as(:dick) do |dick|
      dick.goes_to url_for({ :controller => 'reports', :action => 'emails' }), 'reports/emails'
      dick.fails_authorization url_for({ :controller => 'reports', :action => 'summary' }), url_for({ :controller => 'reports', :action => 'outstanding' })
    end
    new_session_as(:jane) do |jane|
      jane.goes_to url_for({ :controller => 'reports', :action => 'summary' }), 'reports/summary'
      jane.goes_to url_for({ :controller => 'reports', :action => 'outstanding' }), 'reports/outstanding'
      jane.fails_authorization url_for({ :controller => 'reports', :action => 'emails' })
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to url_for({ :controller => 'reports', :action => 'summary' }), 'reports/summary'
      jack.goes_to url_for({ :controller => 'reports', :action => 'outstanding' }), 'reports/outstanding'
      jack.goes_to url_for({ :controller => 'reports', :action => 'emails' }), 'reports/emails'
    end
  end

  # Actions

  def test_summary
    flunk
  end

  def test_outstanding
    new_session_as(:jack) do |jack|
      jack.goes_to(url_for({ :controller => 'reports', :action => 'outstanding' }), 'reports/outstanding')
      jack.assert_assigns :claims, :claims_count, :sellers_count, :total_claims
      # Can't test assigns(:claims) because it has custom attributes
      jack.assert_equal 2, jack.assigns(:claims).size
      jack.assert_equal 2, jack.assigns(:claims_count)
      jack.assert_equal 3, jack.assigns(:sellers_count)
      jack.assert_equal 9, jack.assigns(:total_claims)
    end
  end

end
