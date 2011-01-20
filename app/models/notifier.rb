class Notifier < ActionMailer::Base
  require 'utility_scopes'
  cattr_accessor :from_email_address

  default_url_options[:host] = 'ube.ca'
  @@from_email_address = 'Dawson Book Exchange <dawson@ube.ca>'

  def password_reset(person)
    recipients  person.email_address
    from        from_email_address
    subject     'ube.ca Password Reset'

    @body = {
      :person => person,
      :url => url_for(:host => 'ube.ca', :controller => 'people', :action => 'reset', :token => person.password_token)
    }
  end

  def welcome_email(seller)
    recipients  seller.email_address
    from        from_email_address
    subject     "Welcome to the #{Exchange.current.name}!"

    @body = { :seller => seller }
  end

  def welcome_back(seller)
    recipients  seller.email_address
    from        from_email_address
    subject     "#{Exchange.current.name}: Welcome back!"

    @body = { :seller => seller }
  end

  def reclaim_reminder(seller)
    recipients  seller.email_address
    from        from_email_address
    subject     "#{Exchange.current.name}: Pick up your money and books"

    @body = { :seller => seller }
  end

  def book_sold(id)
    prepare_message(id)
    subject     'You sold a book at ube.ca!'
  end

  def book_unsold(id)
    prepare_message(id)
    subject     'Your book was incorrectly marked sold at ube.ca'
  end

  protected

  def prepare_message(id)
    book = Book.with([ :barcode, :seller ]).find(id)

    recipients  book.seller.email_address
    from        from_email_address

    @body = {
      :book => book,
      :barcode => book.barcode,
      :seller => book.seller,
      :books_sold_count => book.seller.books.count(:conditions => 'sold_at IS NOT NULL'),
      :books_instock_count => book.seller.books.count(:conditions => { :reclaimed_at => nil, :sold_at => nil }),
    }
  end
end
