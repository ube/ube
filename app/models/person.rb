require 'digest/sha2'
class Person < ActiveRecord::Base
  class NotAuthenticated < RuntimeError; end

  # Stores the ID of the person who is currently logged in
  cattr_accessor :current
  class << self; alias_method :current_user, :current; end

  # Stores the unhashed password
  attr_accessor  :password

  # Force password required - for resetting password
  attr_accessor  :password_required

  # Don't let people set the salt
  attr_accessible :name, :email_address, :password, :password_confirmation

  has_many :obligations, :dependent => :destroy
  has_many :roles, :through => :obligations

  validates_presence_of     :name
  validates_length_of       :name, :allow_blank => true, :within => 3..15
  validates_format_of       :name, :allow_blank => true, :with => /^[a-z0-9]+$/i,
                            :message => 'must have letters and numbers only'
  validates_uniqueness_of   :name, :allow_blank => true, :case_sensitive => false

  validates_format_of       :email_address, :allow_blank => true, :with => /^[-a-z0-9%#!+._]+@(?:[-a-z0-9]+\.)+[a-z]{2,6}$/i
  validates_uniqueness_of   :email_address, :allow_blank => true, :case_sensitive => false

  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :minimum => 6,    :allow_blank => true
  validates_confirmation_of :password,                   :allow_blank => true,
                            :message => "The passwords you entered weren't identical"

  before_save :sanitize
  before_save :hash_password
  after_save :clear_password

  # Authenticates a person by her name and unhashed password and returns her ID or nil
  def self.authenticate(name, pass)
    u = find_by_name(name)
    raise ActiveRecord::RecordNotFound unless u
    raise NotAuthenticated unless u.authenticated?(pass)
    u.login!
    u
  end

  def authenticated?(pass)
    self.password_hash == self.class.hash_password(pass, self.salt)
  end

  def login!
    update_attribute :last_login_at, Time.current
  end

  def self.send_password_reset(email)
    u = find_by_email_address(email)
    raise ActiveRecord::RecordNotFound unless u
    u.create_password_token!
    Notifier.deliver_password_reset u
  end
  def self.receive_password_reset(token)
    raise ActiveRecord::RecordNotFound if token.blank?
    u = self.find_by_password_token(token)
    raise ActiveRecord::RecordNotFound unless u
    u
  end

  def create_password_token!
    update_attribute(:password_token, self.class.generate_token { |token| self.class.find_by_password_token(token).nil? } ) if self.password_token.nil?
  end
  def destroy_password_token!
    update_attribute :password_token, nil
  end

  def destroyable?
    self != Person.current && self.name != 'james'
  end

  def available_roles
    self.name == 'james' ? Role.all : self.roles
  end

  def can?(name)
    self.name == 'james' || self.roles.any? { |role| role.name == name }
  end

  def can(name)
    if not can? name
      role = Role.find_or_create_by_name(name)
      self.obligations.create(:role_id => role.id)
    end
  end
  def cannot(name)
    if can? name
      role = Role.find_by_name(name)
      self.obligations.first(:conditions => { :role_id => role.id }).destroy
    end
  end

protected

  def password_required?
    password_hash.blank? || @password_required
  end

  # before_save
  def sanitize
    write_attribute :email_address, self.email_address.downcase unless self.email_address.nil?
  end

  # before_save
  def hash_password
    return if password.blank?
    self.salt = self.class.random_string if new_record?
    self.password_hash = self.class.hash_password(password, self.salt)
  end

  # after_save
  def clear_password
    @password_required = @password = nil
  end

  def self.hash_password(password, salt)
    Digest::SHA256.hexdigest(password + salt)
  end

  def self.random_string(length = 6)
    [Array.new(length){rand(256).chr}.join].pack('m').chomp
  end

  # http://rubyforge.org/projects/uuidtools/ is a bit much, so I'll just use this
  def self.generate_token(size = 40, &block)
    begin
      token = Digest::SHA256.hexdigest(self.random_string(size)).first(32)
    end while not block.call(token) if block_given?
    token
  end

end
