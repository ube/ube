class Book < ActiveRecord::Base
  class InOrder < RuntimeError; end
  class NotInStock < RuntimeError; end

  attr_protected :label, :sale_price, :created_at, :sold_at, :reclaimed_at, :lost_at, :held_at, :state, :delta

  belongs_to :seller
  belongs_to :barcode
  belongs_to :order
  
  belongs_to :creator, :class_name => 'Person', :foreign_key => 'created_by'
  belongs_to :updater, :class_name => 'Person', :foreign_key => 'updated_by'

  acts_as_state_machine :initial => :instock

  validates_presence_of     :price
  validates_numericality_of :price, :only_integer => true, :allow_nil => true
  validates_inclusion_of    :price, :in => 1..300, :allow_blank => true, :message => 'must be between 1 and 300'
  validates_presence_of     :barcode_id, :seller_id

  before_create :set_label
  before_save   :set_sale_price

  named_scope :instock, :conditions => { :state => 'instock' }
  named_scope :lost, :conditions => { :state => 'lost' }
  named_scope :sold, :conditions => { :state => 'sold' }
  named_scope :reclaimed, :conditions => { :state => 'reclaimed' }
  named_scope :unreclaimed, :conditions => { :reclaimed_at => nil }
  named_scope :reclaimable, :conditions => "state <> 'ordered' AND reclaimed_at IS NULL"
  
  # for inventory controller
  named_scope :lost_on, lambda { |date| { :conditions => [ 'SUBSTR(CAST(lost_at AS CHAR(10)), 0, 11) = ?', date.to_date ], :include => :barcode } }
  named_scope :sold_on, lambda { |date| { :conditions => [ 'SUBSTR(CAST(sold_at AS CHAR(10)), 0, 11) = ?', date.to_date ], :include => :barcode } }

  state :instock,     :enter => :mark_instock
  state :lost,        :enter => :mark_lost
  state :held,        :enter => :mark_held
  state :ordered
  state :sold,        :enter => :mark_sold
  state :reclaimed,   :enter => :mark_reclaimed
  # we need this temporary state, because :reclaimed transitions to many states.
  # need to run it as an :after query so that the book is in state :unreclaimed
  # before transitioning to states :instock, :held, and :sold
  state :unreclaimed, :after => :mark_unreclaimed

  event :lose do
    transitions :from => :instock, :to => :lost
  end
  
  event :hold do
    transitions :from => [ :instock, :unreclaimed ], :to => :held
  end
  
  event :order do
    transitions :from => :instock, :to => :ordered
  end

  event :sell do
    transitions :from => [ :ordered, :unreclaimed ], :to => :sold
  end

  event :reclaim do
    transitions :from => [ :instock, :lost, :held, :sold ], :to => :reclaimed
  end

  event :stock do
    transitions :from => [ :lost, :held, :ordered, :sold, :unreclaimed ], :to => :instock
  end

  event :unreclaim do
    transitions :from => :reclaimed, :to => :unreclaimed
  end

  acts_as_ferret :fields => {
    :label => {},
    :title => {},
    :author => {},
    :edition => {},

    :state => { :index => :untokenized },
    :cdrom => { :index => :untokenized },
    :study_guide => { :index => :untokenized },
    :package => { :index => :untokenized },
    :access_code => { :index => :untokenized },

    :sort_label => { :index => :untokenized },
    :sort_state => { :index => :untokenized },
    :sort_price => { :index => :untokenized },
    :sort_sale_price => { :index => :untokenized },

    :sort_title => { :index => :untokenized },
    :sort_author => { :index => :untokenized },
    :sort_edition => { :index => :untokenized },
    :sort_retail_price => { :index => :untokenized },
  }

  # acts_as_ferret
  def title
    barcode.title
  end
  def author
    barcode.author
  end
  def edition
    barcode.edition
  end

  def sort_label
    self.label
  end
  def sort_state
    self.state
  end
  def sort_price
    self.price
  end
  def sort_sale_price
    self.sale_price
  end

  def sort_title
    barcode.title
  end
  def sort_author
    barcode.author
  end
  # acts_as_ferret is confused if string starts with integer
  def sort_edition
    "-#{barcode.edition}"
  end
  def sort_retail_price
    barcode.retail_price
  end

  def self.calculate_sale_price(price, handling_fee)
    if price > 1
      price + (price * handling_fee.to_f / 100).ceil
    else
      1
    end
  end

protected

  def mark_instock
    if lost?
      update_attribute :lost_at, nil
    elsif held?
      update_attribute :held_at, nil
    elsif sold?
      update_attribute :sold_at, nil
      
      if order.nil?
        logger.warn "[ERROR] Sold book #{self.id} had no order."
      else
        order.remove_book(self)
      end

      unless seller.email_address.blank?
        Notifier.deliver_book_unsold id
      end
    end
  end

  def mark_lost
    update_attribute :lost_at, Time.current
  end
  
  def mark_held
    if instock? # don't run on unreclaim!
      update_attribute :held_at, Time.current
    end
  end

  def mark_sold
    if ordered? # don't run on unreclaim!
      update_attribute :sold_at, Time.current

      barcode.touch

      unless seller.email_address.blank?
        Notifier.deliver_book_sold id
      end
    end
  end

  def mark_reclaimed
    update_attribute :reclaimed_at, Time.current

    if lost?
      # mark_instock and mark_sold, but don't send mail
      update_attribute :lost_at, nil
      update_attribute :sold_at, Time.current
    end
  end

  def mark_unreclaimed
    update_attribute :reclaimed_at, nil

    if sold_at
      sell!
    elsif held_at
      hold!
    else
      stock!
    end
  end

  def set_label
    write_attribute :label, self.class.maximum('label').to_i + 1 # to_i makes nil 0
  end

  def set_sale_price
    write_attribute :sale_price, self.class.calculate_sale_price(self.price, Exchange.current.handling_fee)
  end

  def validate_on_update
    if price_changed?
      errors.add(:price, 'cannot change if book is in checkout')  if ordered?
      errors.add(:price, 'cannot change if book is already sold') if sold?
      errors.add(:price, 'cannot change if book is reclaimed')    if reclaimed?
    end
  end
end
