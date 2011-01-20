class Cart
  require 'utility_scopes'
  class AlreadyInCart < RuntimeError; end
  class NotInCart < RuntimeError; end

  attr_reader :books
  attr_reader :total_price

  def initialize
    empty!
  end

  def empty!
    @books = []
    @total_price = 0.0
  end

  def add_book(book)
    raise Book::InOrder if book.ordered?
    raise Book::NotInStock unless book.instock?
    raise Cart::AlreadyInCart if has_book?(book)
    @books << book.id
    @total_price += book.sale_price
  end

  def remove_book(book)
    raise Cart::NotInCart unless has_book?(book)
    @books.delete(book.id)
    @total_price -= book.sale_price
  end

  def has_book?(book)
    @books.include?(book.id)
  end
end
