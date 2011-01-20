class Order < ActiveRecord::Base
  attr_protected :completed_at, :created_at, :updated_at, :created_by, :updated_by

  has_many :books

  belongs_to :creator, :class_name => 'Person', :foreign_key => 'created_by'
  belongs_to :updater, :class_name => 'Person', :foreign_key => 'updated_by'

  before_destroy :clear

  def fill!(collection)
    self.books = collection
    self.books.each { |book| book.order! }
  end

  def complete!
    self.books.each { |book| book.sell! }
    update_attribute :completed_at, Time.current
  end

  def remove_book(book)
    self.books.delete(book)
    self.destroy if self.books.empty?
  end

  def total
    self.books.inject(0) { |memo, book| memo + book.sale_price }
  end

protected

  def clear
    self.books.each { |book| book.stock! }
    self.books.clear
  end
end
