require "#{File.dirname(__FILE__)}/../test_helper"

class PeopleTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  # Permit

  def test_should_deny_all_except_forgot_and_reset_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication people_path, new_person_path, edit_person_path(people(:jack)), change_password_person_path(people(:jack))
      # forgot and reset already tested in functional test
    end
  end

  def test_should_deny_some_if_not_authorized
    new_session_as(:joe) do |joe|
      joe.fails_authorization people_path, new_person_path, edit_person_path(people(:jack))
    end
  end

  def test_should_allow_some_if_authenticated
    new_session_as(:joe) do |joe|
      joe.goes_to change_password_person_path(people(:joe).id), 'people/change_password'
      # forgot and reset already tested in functional test
    end
  end

  def test_should_allow_all_if_authorized
    new_session_as(:jack) do |jack|
      jack.goes_to people_path, 'people/index'
      jack.goes_to new_person_path, 'people/new'
      jack.goes_to edit_person_path(people(:joe).id), 'people/edit'
      jack.goes_to change_password_person_path(people(:jack)), 'people/change_password'
    end
  end

  # Forms

  # just test a few
  def test_should_remember_values_on_create
    new_session_as(:jack) do |jack|
      jack.assert_remember people_path, 'people/new', {}, :person, :name
    end
  end

  # just test a few
  def test_should_report_errors_on_create
    new_session_as(:jack) do |jack|
      jack.assert_report people_path, 'people/new', {}, :person, nil, :name, :password
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to people_path, 'people/index'
      jack.assert_assigns :people
      jack.assert_equal_with_permutation [ people(:dick), people(:jack), people(:james), people(:joe), people(:jane) ], jack.assigns(:people)
    end
  end

  def test_new
    new_session_as(:jack) do |jack|
      jack.goes_to new_person_path, 'people/new'
      jack.assert_assigns :person, :roles
      jack.assert_equal 8, jack.assigns(:roles).size
    end
  end

  def test_create
    new_session_as(:jack) do |jack|
      assert_difference 'Person.count' do
        jack.post people_path, :person => valid_record
        jack.assert_flash :notice
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_edit
    new_session_as(:jack) do |jack|
      jack.goes_to edit_person_path(people(:joe)), 'people/edit'
      jack.assert_assigns :person, :roles
      jack.assert_equal people(:joe), jack.assigns(:person)
      jack.assert_equal 8, jack.assigns(:roles).size
    end
  end

  def test_update
    new_session_as(:jack) do |jack|
      assert_change people(:joe), :name, :email_address, :password_hash do
        jack.put person_path(people(:joe)), :person => valid_record
        jack.assert_flash :notice
        jack.is_redirected_to 'people/index'
      end
    end
  end

  # Change password

  def test_change_password
    new_session_as(:jack) do |jack|
      assert_change people(:jack), :password_hash do
        jack.post change_password_person_path(people(:jack)), :person => { :password => 'password', :password_confirmation => 'password' }
        jack.assert_flash :notice
        jack.is_redirected_to 'about/dashboard'
      end
    end
  end

  def test_change_password_with_different_path
    new_session_as(:jack) do |jack|
      assert_change people(:jack), :password_hash do
        assert_no_change people(:joe), :password_hash do
          jack.post change_password_person_path(people(:joe)), :person => { :password => 'password', :password_confirmation => 'password' }
          jack.assert_flash :notice
          jack.is_redirected_to 'about/dashboard'
        end
      end
    end
  end

  def test_change_password_with_different_parameters
    new_session_as(:jack) do |jack|
      assert_change people(:jack), :password_hash do
        assert_no_change people(:jack), :name, :email_address do
          jack.post change_password_person_path(people(:jack)), :person => valid_record
          jack.assert_flash :notice
          jack.is_redirected_to 'about/dashboard'
        end
      end
    end
  end

  # Destruction

  def test_destroy_with_no_id
    new_session_as(:jack) do |jack|
      assert_no_difference 'Person.count' do
        jack.delete person_path('dummy')
        jack.assert_no_flash :notice
        jack.assert_flash :error
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_destroy_with_one_id
    new_session_as(:jack) do |jack|
      assert_difference 'Person.count', -1 do
        jack.delete person_path(people(:dick))
        jack.assert_flash :notice
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_destroy_james
    new_session_as(:jack) do |jack|
      assert_no_difference 'Person.count' do
        jack.delete person_path(people(:james))
        jack.assert_flash :error
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_destroy_yourself
    new_session_as(:jack) do |jack|
      assert_no_difference 'Person.count' do
        jack.delete person_path(people(:jack))
        jack.assert_flash :error
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_destroy_james_with_many_id
    new_session_as(:jack) do |jack|
      assert_difference 'Person.count', -1 do
        jack.delete person_path('dummy'), :ids => [ people(:dick).id, people(:james).id ]
        jack.assert_flash :notice
        jack.assert_flash :error
        jack.is_redirected_to 'people/index'
      end
    end
  end

  def test_destroy_yourself_with_many_id
    new_session_as(:jack) do |jack|
      assert_difference 'Person.count', -1 do
        jack.delete person_path('dummy'), :ids => [ people(:dick).id, people(:jack).id ]
        jack.assert_flash :error
        jack.is_redirected_to 'people/index'
      end
    end
  end

protected

  def valid_record(options = {})
    { :name => 'nadia',
      :email_address => 'nadia@example.com',
      :password => 'password',
      :password_confirmation => 'password',
    }.merge(options)
  end
end
