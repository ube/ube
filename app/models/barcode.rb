class Barcode < ActiveRecord::Base
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
      self.send("#{attr}=", self.class.pre_sanitize(self.send(attr)))
      send("sanitize_#{attr}") unless self.send(attr).blank?
      self.class.post_sanitize(self.send(attr))
      write_attribute attr, self.send(attr)
    end
  end

  def self.pre_sanitize(attr)
    return if attr.blank?
    attr.downcase!
    attr.gsub!(/\bw\/\s/, 'With ') # expand abbreviations
    attr.delete!('`') # remove ` (missed tab key)
    attr.strip!
    attr = attr.titleize
    attr.gsub!("'S", "'s")
    attr.gsub!("'T", "'t")
    attr
  end

  def self.post_sanitize(attr)
    return if attr.blank?
    attr.strip!
    attr.squeeze!(' ')
    attr.gsub!(' ,', ',')
  end

  def sanitize_author
    if self.author =~ /^(?:unknown|no author|anon|n[\/ ]?a)$/i
      self.author = 'NA'
    else
      self.author.gsub!(/[&\/]+/, ', ')
      self.author.gsub!(/\bEt All?\.?$/, 'et al')
      self.author.gsub!(/,\s*/, ', ')
    end
  end

  def sanitize_title
    self.title.gsub!('Volume', 'Vol')
    self.title.gsub!(/Study Guide(?: Only)?$/, 'STUDY GUIDE')
  end

  def sanitize_edition
    if self.edition =~ /^n[\/ ]?a$/i
      self.edition = nil
    elsif self.edition =~ /^(?:Volume|Vol)\s+(\d+)$/
      self.title  += " Vol #{$1}"
      self.edition = nil
    else
      EDITION_SUBST.each { |k,v| self.edition.gsub!(k, v) }
      self.edition.gsub!(/^([0-9]+)(?:st|nd|rd|th)$/i, '\1') # lonely ordinals
    end
  end
end
