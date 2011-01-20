require File.dirname(__FILE__) + '/../test_helper'
require 'people_controller'

# Re-raise errors caught by the controller.
class PeopleController; def rescue_action(e) raise e end; end

class PeopleControllerTest < ActionController::TestCase
  fixtures :people, :exchanges, :addresses

  def setup
    @controller = PeopleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear
  end

  # Forgot

  def test_forgot
    get :forgot
    assert_render 'forgot'
  end

  def test_submit_forgot
    assert_change people(:joe), :password_token do
      post :forgot, :person => { :email_address => people(:joe).email_address }
      assert_render 'sent_password_reset'
    end
  end

  def test_should_remember_email_address_on_forgot
    post :forgot, :person => { :email_address => 'wrong' }
    assert_render 'forgot'
    assert_assigns :email_address
    assert_equal 'wrong', assigns(:email_address)
  end

  def test_should_display_error_if_email_address_blank_on_forgot
    post :forgot, :person => { :email_address => nil }
    assert_render 'forgot'
  end

  def test_should_display_error_if_email_address_not_found_on_forgot
    post :forgot, :person => { :email_address => 'wrong' }
    assert_render 'forgot'
  end



  # Reset

  def test_reset
    get :reset, :token => people(:jack).password_token
    assert_render 'reset'
    assert_assigns :person
    assert_equal people(:jack), assigns(:person)
  end

  def test_submit_reset
    assert_change people(:jack), :password_hash, :password_token do
      post :reset, :token => people(:jack).password_token, :person => { :password => 'jack_password', :password_confirmation => 'jack_password' }
      assert_redirected_to home_path

      # handle login
      assert_equal people(:jack).id, session[:person]
      assert_nil @request.cookies[:remember_me_token]

      # flash
      assert_flash :notice
    end
  end

  def test_should_display_error_if_token_blank_on_reset
    get :reset, :token => nil
    assert_render 'couldnt_process_request'
    assert_not_assigns :person
  end

  def test_should_display_error_if_token_not_found_on_reset
    get :reset, :token => 'wrong'
    assert_render 'couldnt_process_request'
    assert_not_assigns :person
  end

  def test_should_report_errors_on_reset
    assert_report :reset, 'reset', { :token => people(:jack).password_token }, :person, nil, :password
  end

protected

  def create_person(options = {})
    post :create, :person => {
      :name => 'james',
      :email_address => 'james@example.com',
      :password => 'testpass',
      :password_confirmation => 'testpass',
    }.merge(options)
  end
end
