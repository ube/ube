class Barcode < ActiveRecord::Base
  require 'utility_scopes'
  
  EDITION_SUBST = {
   ','          => ' ',
   'Edition'    => '',
   'First'      => '1st',
   'Second'     => '2nd',
   'Third'      => '3rd',
   'Fourth'     => '4th',
   'Fifth'      => '5th',
   'Sixth'      => '6th',
   'Seventh'    => '7th',
   'Eigth'      => '8th',
   'Eighth'     => '8th',
   'Ninth'      => '9th',
   'Tenth'      => '10th',
   'Eleventh'   => '11th',
   'Twelfth'    => '12th',
   'Thirteenth' => '13th',
   'Fourteenth' => '14th',
   'Fifteenth'  => '15th',
  }.freeze

  attr_protected :created_at, :updated_at, :delta

  has_many :books, :dependent => :destroy

  validates_presence_of     :tag
  validates_uniqueness_of   :tag, :allow_blank => true
  validates_numericality_of :tag, :only_integer => true
  validates_numericality_of :retail_price, :only_integer => true, :allow_nil => true
  validates_presence_of     :title, :author

  before_save :sanitize

  acts_as_ferret :fields => {
    :tag => {},
    :title => {},
    :author => {},
    :edition => {},

    :sort_tag => { :index => :untokenized },
    :sort_title => { :index => :untokenized },
    :sort_author => { :index => :untokenized },
    :sort_edition => { :index => :untokenized },
    :sort_retail_price => { :index => :untokenized },
  }

  # acts_as_ferret
  def sort_tag
    self.tag
  end
  def sort_title
    self.title
  end
  def sort_author
    self.author
  end
  def sort_edition
    "-#{self.edition}"
  end
  def sort_retail_price
    self.retail_price
  end

  protected

  def sanitize
    [ :title, :author, :edition ].each do |attr|
      self[attr] = self.class.pre_sanitize(self[attr])
      self[attr] = send("sanitize_#{attr}") unless self[attr].blank?
      self[attr] = self.class.post_sanitize(self[attr])
    end
  end

  # remove ` (missed tab key), expand abbreviations
  def self.pre_sanitize(value)
    value.downcase.delete('`').gsub(/\bw\/\s/, 'With ').strip.titleize.gsub("'S", "'s").gsub("'T", "'t") unless value.nil?
  end

  def self.post_sanitize(value)
    value.strip.squeeze(' ').gsub(' ,', ',') unless value.nil?
  end

  def sanitize_author
    if self.author =~ /^(?:unknown|no author|anon|n[\/ ]?a)$/i
      'NA'
    elsif self.author?
      self.author.gsub(/[&\/]+/, ', ').gsub(/\bEt All?\.?$/, 'et al').gsub(/,\s*/, ', ')
    end
  end

  def sanitize_title
    self.title.gsub('Volume', 'Vol').gsub(/Study Guide(?: Only)?$/, 'STUDY GUIDE') if self.title?
  end

  def sanitize_edition
    if self.edition =~ /^n[\/ ]?a$/i
      self.edition = nil
    elsif self.edition =~ /^(?:Volume|Vol)\s+(\d+)$/
      self.title += " Vol #{$1}"
      self.edition = nil
    else
      EDITION_SUBST.each { |k,v| self.edition.gsub!(k, v) }
      self.edition.gsub!(/^([0-9]+)(?:st|nd|rd|th)$/i, '\1') # lonely ordinals
    end
    self.edition
  end
end
