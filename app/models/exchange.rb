class Exchange < ActiveRecord::Base
  cattr_accessor :current

  attr_protected :created_at

  acts_as_addressable
  validates_multiparameter_assignments
  has_attached_file :schedule,
    :storage => :s3,
    :s3_credentials => {
      :access_key_id => ENV['AWS_ACCESS_KEY_ID'] || 'TEST',
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'] || 'TEST',
    },
    :bucket => ENV['AWS_BUCKET'],
    :path => ':attachment/:basename.:extension'

  validates_presence_of     :name
  validates_uniqueness_of   :name, :case_sensitive => false

  validates_presence_of     :email_address
  validates_format_of       :email_address, :with => /^[-a-z0-9%\#!+._]+@(?:[-a-z0-9]+\.)+[a-z]{2,6}$/i, :allow_blank => true

  validates_presence_of     :handling_fee, :service_fee, :early_reclaim_penalty
  validates_numericality_of :handling_fee, :allow_nil => true
  validates_numericality_of :service_fee, :only_integer => true, :allow_nil => true
  validates_numericality_of :early_reclaim_penalty, :only_integer => true, :allow_nil => true

  validates_presence_of     :sale_starts_on, :sale_ends_on, :reclaim_starts_on, :reclaim_ends_on, :ends_at, :hours

  before_save :sanitize
  after_update :update_sale_prices_on_books

  def self.current
    @@current ||= Exchange.with(:address).first
  end

  def self.destroy_current
    @@current = nil
  end

  def early_reclaim?
    Date.current < reclaim_starts_on
  end

  def late_reclaim?
    Date.current > reclaim_ends_on
  end

protected

  def update_sale_prices_on_books
    if handling_fee_changed?
      Book.update_all 'sale_price = price + CEIL(price * %s / 100)' % self.handling_fee, 'price > 1'
      Book.rebuild_index
    end
  end

  def sanitize
    write_attribute :email_address, self.email_address.downcase unless self.email_address.nil?
  end
end
