class Address < ActiveRecord::Base
  attr_protected :addressable_id, :addressable_type

  belongs_to :addressable, :polymorphic => true
  
  def empty?
    [ address, city, region, country, postal_code ].all? { |attr| attr.blank? }
  end
  
  def to_s(format = nil)
    case format
    when :comma
      fields = []
      fields << address.gsub(/(\r|\n)+/, ", ") unless address.blank?
      fields << city        unless city.blank?
      fields << region      unless region.blank?
      fields << postal_code unless postal_code.blank?

      fields.join(', ')
    else
      fields = []
      fields << city        unless city.blank?
      fields << region      unless region.blank?
      fields << postal_code unless postal_code.blank?

      out  = ''
      out += "#{address}\n" unless address.blank?
      out += fields.join(', ')
    end
  end
  
end
