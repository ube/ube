require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :people, :obligations, :roles

  def setup
    @emails = ActionMailer::Base.deliveries 
    @emails.clear
  end

  # Save

  def test_should_downcase_email_address
    assert_filter :email_address, 'EXAMPLE@EXAMPLE.COM', 'example@example.com'
  end

  def test_should_create_salt_before_save
    u = create_record
    assert_not_nil u.salt
  end

  def test_should_hash_password_before_save
    u = create_record
    assert_not_nil u.password_hash
  end

  def test_should_clear_password_after_save
    u = create_record
    assert_nil u.password
  end

  # Create

  def test_should_create_person
    assert_difference 'Person.count' do
      assert create_record.valid?
    end
  end

  # Update

  def test_should_update_password
    assert_change people(:jack), :password_hash do
      assert_update Person, people(:jack).id, :password => 'jack_password', :password_confirmation => 'jack_password'
    end
    assert_equal people(:jack), Person.authenticate('jack5', 'jack_password')
  end

  def test_should_not_update_salt
    assert_no_change people(:jack), :salt do
      assert_update Person, people(:jack).id, :password => 'jack_password', :password_confirmation => 'jack_password'
    end
    assert_equal people(:jack), Person.authenticate('jack5', 'jack_password')
  end

  def test_should_update_name_and_not_hash_password
    assert_change people(:jack), :name do
      assert_update Person, people(:jack).id, :name => 'jacqueline'
    end
    assert_equal people(:jack), Person.authenticate('jacqueline', 'testpass')
  end



  # Validations

  def test_should_require_name
    assert_presence_of_attributes Person, {}, :name
  end
  def test_should_require_name_with_3_to_15_characters
    assert_length_of_attributes Person, { :range => 3..15 }, :name
  end
  def test_should_require_name_with_only_alphanumeric_characters
    assert_invalid_values create_record, :name, 'not_valid'
  end
  def test_should_require_unique_name
    assert_uniqueness_of_attributes Person, { :case_insensitive => true }, :name
  end

  def test_should_require_valid_email_address
    assert_invalid_values create_record, :email_address, 'not_valid'
  end
  def test_should_require_unique_email_address
    assert_uniqueness_of_attributes Person, { :case_insensitive => true }, :email_address
  end


  def test_should_require_password
    assert_presence_of_attributes Person, {}, :password
  end
  def test_should_require_password_with_at_least_6_characters
    assert_minimum_length_of_attributes Person, { :min => 6 }, :password
  end
  def test_should_require_confirmation_of_password
    assert_confirmation_of_attributes Person, { :message => "The passwords you entered weren't identical" }, :password
  end



  # Authentication

  def test_should_authenticate_person
    assert_equal people(:jack), Person.authenticate('jack5', 'testpass')
  end

  def test_should_not_authenticate_person_with_wrong_name
    assert_raise(ActiveRecord::RecordNotFound) { Person.authenticate('wrong', 'testpass') }
  end

  def test_should_not_authenticate_person_with_wrong_password
    assert_raise(Person::NotAuthenticated) { Person.authenticate('jack5', 'wrong') }
  end

  def test_should_update_last_login_timestamp_on_authentication
    assert_change people(:jack), :last_login_at do
      u = Person.authenticate('jack5', 'testpass')
      assert_in_delta Time.current.to_i, u.last_login_at.to_i, 1.hour
    end
  end



  # Password reset

  def test_should_not_send_password_reset_with_wrong_email_address  
    assert_raise(ActiveRecord::RecordNotFound) { Person.send_password_reset('wrong') }
  end

  def test_should_create_password_token_on_send_password_reset
    assert_change people(:joe), :password_token do
      assert Person.send_password_reset(people(:joe).email_address)
    end
  end

  def test_should_send_password_reset
    Person.send_password_reset(people(:joe).email_address)

    response = @emails.first
    assert_equal 1, @emails.size
    assert_equal "dawson@ube.ca", response.from[0]
    assert_equal people(:joe).email_address, response.to[0]
    assert_equal "ube.ca Password Reset", response.subject
  end

  def test_should_receive_password_reset
    assert_equal people(:jack), Person.receive_password_reset(people(:jack).password_token)
  end

  def test_should_not_receive_password_reset_without_token
    assert_raise(ActiveRecord::RecordNotFound) { Person.receive_password_reset(nil) }
  end

  def test_should_not_receive_password_reset_with_wrong_token
    assert_raise(ActiveRecord::RecordNotFound) { Person.receive_password_reset('wrong') }
  end



  # Tokens

  def test_should_not_overwrite_password_token
    assert_nil people(:jack).create_password_token!
  end
  def test_should_create_password_token
    assert_create_token 'password', people(:joe)
  end
  def test_should_destroy_password_token
    assert_destroy_token 'password', people(:jack)
  end



  # Destroy

  def test_should_not_destroy_james
    assert_false people(:james).destroyable?
  end

  def test_should_not_destroy_yourself
    Person.current = people(:jack)
    assert_false people(:jack).destroyable?
  end

  # Roles

  def test_available_roles
    Person.current = people(:joe)
    assert_equal Person.current.available_roles, []
    Person.current = people(:jack)
    assert_equal_with_permutation Person.current.available_roles, Role.all
    Person.current = people(:james)
    assert_equal_with_permutation Person.current.available_roles, Role.all
  end

  def test_has_role
    assert people(:jack).can?('edit_exchange')
    assert !people(:dick).can?('edit_exchange')
  end

  def test_grant_role
    assert !people(:dick).can?('edit_exchange')
    people(:dick).can('edit_exchange')
    assert people(:dick).reload.can?('edit_exchange')
  end

  def test_revoke_role
    assert people(:jack).can?('edit_exchange')
    people(:jack).cannot('edit_exchange')
    assert !people(:jack).reload.can?('edit_exchange')
  end

  protected
    def create_record(options = {})
      Person.create({ :name => 'dave5', 
                      :email_address => 'dave@example.com',
                      :password => 'dave_password',
                      :password_confirmation => 'dave_password' }.merge(options))
    end

    def assert_create_token(name, fixture, expiry = false)
      assert_nil fixture.send("#{name}_token")
      fixture.send("create_#{name}_token!")
      assert_not_nil fixture.send("#{name}_token")
    end

    def assert_destroy_token(name, fixture, expiry = false)
      assert_not_nil fixture.send("#{name}_token")
      fixture.send("destroy_#{name}_token!")
      assert_nil fixture.send("#{name}_token")
    end
end
