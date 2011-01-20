ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all
  
  # Add more helper methods to be used by all tests here...

  include TestSuite::ControllerAssertions
  include TestSuite::ModelAssertions
  include TestSuite::BasicAssertions

  ### Stubs ###############################################################

  include RR::Adapters::TestUnit

  ### Integration ###############################################################

  module MyIntegrationDSL
    attr_reader :person

    # Login

    def goes_to_login
      get new_session_path
      assert_render 'sessions/new'
    end

    def adds_to_cart(book)
      put cart_cart_item_path(books(book))
    end

    def logs_in_as(person)
      post sessions_path, :person => { :name => people(person).name, :password => 'testpass' }
      is_redirected_to 'about/dashboard'
    end

    # Permit

    def fails_authentication(*urls)
      urls.each do |url|
        is_denied_and_redirected_to url, 'sessions/new'
      end
    end

    def fails_authorization(*urls)
      urls.each do |url|
        is_denied_and_redirected_to url, 'about/dashboard'
      end
    end

    def is_denied_and_redirected_to(url, template)
      get url
      assert_flash :error
      is_redirected_to template
    end
  end

  # Create new sessions

  def new_session
    open_session do |sess|
      sess.extend(RR::Adapters::TestUnit)
      sess.extend(TestSuite::IntegrationDSL)
      sess.extend(MyIntegrationDSL)
      yield sess if block_given?
    end
  end

  def new_session_as(person)
    new_session do |sess|
      sess.goes_to_login
      sess.logs_in_as(person)
      yield sess if block_given?
    end
  end

  # Fixtures

  def with_reclaim(start_date, end_date)
    old_start_date = Exchange.current.reclaim_starts_on
    old_end_date = Exchange.current.reclaim_ends_on
    Exchange.current.update_attribute :reclaim_starts_on, start_date
    Exchange.current.update_attribute :reclaim_ends_on, end_date
    Exchange.destroy_current

    yield

    Exchange.current.update_attribute :reclaim_starts_on, old_start_date
    Exchange.current.update_attribute :reclaim_ends_on, old_end_date
    Exchange.destroy_current
  end
end
