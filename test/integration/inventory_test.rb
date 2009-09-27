require "#{File.dirname(__FILE__)}/../test_helper"

class InventoryTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication url_for(:controller => 'inventory', :action => 'index'),
                                 url_for(:controller => 'inventory', :action => 'all'),
                                 url_for(:controller => 'inventory', :action => 'sold_on'),
                                 url_for(:controller => 'inventory', :action => 'lost_on')
    end
  end

  def test_should_allow_all_if_authenticated
    new_session_as(:joe) do |joe|
      joe.goes_to url_for(:controller => 'inventory', :action => 'index'), 'inventory/index'
      joe.goes_to url_for(:controller => 'inventory', :action => 'all'), 'inventory/all'
      joe.goes_to url_for(:controller => 'inventory', :action => 'sold_on'), 'inventory/all'
      joe.goes_to url_for(:controller => 'inventory', :action => 'lost_on'), 'inventory/all'
    end
  end

  def test_all
    new_session_as(:jack) do |jack|
      jack.goes_to url_for(:controller => 'inventory', :action => 'all'), 'inventory/all'
      jack.assert_assigns :books
      jack.assert_equal_with_permutation [ books(:instock), books(:bob_instock), books(:joe_instock) ], jack.assigns(:books)
    end
  end

  def test_sold_on
    new_session_as(:jack) do |jack|
      jack.goes_to url_for(:controller => 'inventory', :action => 'sold_on', :sold_on => 1.day.ago.utc.to_date), 'inventory/all'
      jack.assert_assigns :books
      jack.assert_equal [ books(:sold) ], jack.assigns(:books)
    end
  end

  def test_lost_on
    new_session_as(:jack) do |jack|
      jack.goes_to url_for(:controller => 'inventory', :action => 'lost_on', :lost_on => 1.day.ago.utc.to_date), 'inventory/all'
      jack.assert_assigns :books
      jack.assert_equal [ books(:lost) ], jack.assigns(:books)
    end
  end

end
