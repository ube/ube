require "#{File.dirname(__FILE__)}/../test_helper"

class HeldBooksTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def test_create
    new_session_as(:jack) do |jack|
      jack.put held_book_path(books(:instock))
      jack.assert books(:instock).reload.held?
    end
  end

  def test_destroy
    new_session_as(:jack) do |jack|
      jack.delete held_book_path(books(:held))
      jack.assert books(:held).reload.instock?
    end
  end
end
