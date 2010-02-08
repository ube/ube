class Seller < ActiveRecord::Base
  cattr_accessor :current

  attr_protected :contract_printed_at, :welcome_email_sent_at, :paid_service_fee_at, :late_reclaimer_on, :welcome_back_sent_on, :reclaim_reminder_sent_on, :created_at, :updated_at, :delta

  has_many :books, :dependent => :destroy

  validates_presence_of   :name
  validates_format_of     :telephone, :with => /^[^a-z]*$/i, :message => "can't contain letters"
  validates_format_of     :email_address, :with => /^[-a-z0-9%\#!+._]+@(?:[-a-z0-9]+\.)+[a-z]{2,6}$/i, :allow_blank => true
  validates_uniqueness_of :email_address, :allow_blank => true, :case_sensitive => false

  before_save :sanitize

  # acts_as_ferret
  def sort_name
    self.name
  end
  def sort_telephone
    self.telephone
  end
  # acts_as_ferret is confused if string starts with integer
  def sort_email_address
    "-#{self.email_address}"
  end

  def print_contract!
    update_attribute :contract_printed_at, Time.current
  end

  def send_welcome_email!
    unless email_address.blank? or welcome_email_sent_at?
      update_attribute :welcome_email_sent_at, Time.current
      Notifier.deliver_welcome_email self
    end
  end

  def pay_service_fee!
    update_attribute :paid_service_fee_at, Time.current unless paid_service_fee_at?
  end
  def unpay_service_fee!
    update_attribute :paid_service_fee_at, nil if paid_service_fee_at?
  end

  def late_reclaimer?
    !late_reclaimer_on.blank?
  end
  def late_reclaimer!
    update_attribute :late_reclaimer_on, Date.current
  end

  def reclaim!(books = self.books.reclaimable)
    credit = 0

    credit = books.inject(0)  { |memo, book| (book.sold? || book.lost?) ? memo + book.price : memo }
    books.each { |book| book.reclaim! }

    if Exchange.current.early_reclaim?
      credit -= books.size * Exchange.current.early_reclaim_penalty
    elsif Exchange.current.late_reclaim?
      late_reclaimer!
    end

    unless paid_service_fee_at?
      pay_service_fee!
      credit -= Exchange.current.service_fee
    end

    credit
  end

  # TODO: test this method
  def self.recipients_for_welcome_back
    sellers = Seller.all
    sellers.reject! { |seller| seller.email_address.blank? || seller.welcome_back_sent_on? }
    sellers
  end
  def send_welcome_back!
    unless email_address.blank? or welcome_back_sent_on?
      update_attribute :welcome_back_sent_on, Date.current
    end
  end

  # TODO: test this method
  def self.recipients_for_reclaim_reminder
    sellers = Seller.all(:conditions => { :books => { :reclaimed_at => nil } }, :joins => :books)
    sellers.reject! { |seller| seller.email_address.blank? || seller.reclaim_reminder_sent_on? }
    sellers
  end
  def send_reclaim_reminder!
    unless email_address.blank? or reclaim_reminder_sent_on?
      update_attribute :reclaim_reminder_sent_on, Date.current
    end
  end

  protected

  def before_destroy
    books.empty?
  end

  def sanitize
    write_attribute :name, self.name.downcase.titleize
    write_attribute :telephone, self.telephone.delete('^0-9') unless self.telephone.nil?
    write_attribute :email_address, self.email_address.downcase unless self.email_address.nil?
  end
end
