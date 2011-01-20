require File.dirname(__FILE__) + '/../test_helper'
require 'sessions_controller'

# Re-raise errors caught by the controller.
class SessionsController; def rescue_action(e) raise e end; end

class SessionsControllerTest < ActionController::TestCase
  fixtures :people

  def setup
    @controller = SessionsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails     = ActionMailer::Base.deliveries
    @emails.clear

    @request.cookies['ube'] = '2f4dd9980c644a91fb8c4ecc93c3cc701181a20274378a521407573a57d2db666cf54d475e8d091b9de00bc76c24eb6b67a3b4dea2b50ad481468bc5fc58f931'
  end

  # Login

  def test_new
    get :new
    assert_render 'new'
  end

  def test_should_redirect_to_home_if_logged_in_on_new
    create_session :joe
    get :new # try to create another new session
    assert_redirected_to home_path
  end

  def test_should_remember_name_on_create
    create_session :joe, :password => nil
    assert_render 'new'
    assert_assigns :name
    assert_equal people(:joe).name, assigns(:name)
  end

  def test_should_display_error_if_name_blank_on_create
    create_session :joe, :name => nil
    assert_render 'new'
  end
  def test_should_display_error_if_password_blank_on_create
    create_session :joe, :password => nil
    assert_render 'new'
  end
  def test_should_display_error_if_name_and_password_blank_on_create
    create_session :joe, :name => nil, :password => nil
    assert_render 'new'
  end

  def test_should_display_error_if_person_not_found_on_create
    create_session :joe, :name => 'wrong'
    assert_render 'new'
  end

  def test_should_display_error_if_person_not_authenticated_on_create
    create_session :joe, :password => 'wrong'
    assert_render 'new'
  end

  def test_create
    assert_change people(:joe), :last_login_at do
      create_session :joe
      assert_redirected_to home_path

      # handle login
      assert_equal people(:joe).id, session[:person]
    end
  end

  def test_should_redirect_to_return_to_after_create
    @request.session[:return_to] = "/bogus/location"
    create_session :joe
    assert_redirected_to "http://test.host/bogus/location"
  end

  def test_should_destroy_session
    create_session :jack

    get :destroy
    assert_redirected_to new_session_path

    # handle_logout
    assert_nil session[:person]

    # repeat logout shouldn't break
    get :destroy
    assert_redirected_to new_session_path
  end

protected

  # same password for all fixtures
  def create_session(person, options = {})
    post :create, :person => { :name => people(person).name, :password => 'testpass' }.merge(options)
  end
end
