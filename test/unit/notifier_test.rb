require File.dirname(__FILE__) + '/../test_helper'
require 'notifier'

class NotifierTest < ActionMailer::TestCase
  fixtures :sellers, :books, :people, :exchanges, :addresses

  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_password_reset
    person = people(:jack)

    response = Notifier.create_password_reset(person)

    assert_equal "ube.ca Password Reset", response.subject
    assert_equal "dawson@ube.ca", response.from[0]
    assert_equal person.email_address, response.to[0]

    assert_match /#{person.name} -/, response.body
    assert_match %r{http://ube.ca/people/reset/#{person.password_token}}, response.body
  end

  def test_welcome_email
    seller = sellers(:jack)

    response = Notifier.create_welcome_email(seller)

    assert_equal "Welcome to the Dawson Book Exchange!", response.subject
    assert_equal "dawson@ube.ca", response.from[0]
    assert_equal seller.email_address, response.to[0]

    assert_match /#{seller.name} -/, response.body
    assert_match %r{http://ube.ca/contract\?email=jack%40example.com}, response.body
    assert_match %r{http://ube.ca/status\?email=jack%40example.com}, response.body
    assert_match %r{http://ube.ca/about/help}, response.body
    assert_match %r{http://ube.ca/}, response.body
  end

  def test_book_sold
    book = books(:instock)

    response = Notifier.create_book_sold(book)

    assert_equal "You sold a book at ube.ca!", response.subject
    check_email_to_seller(response, book)
  end

  def test_book_unsold
    book = books(:sold)

    response = Notifier.create_book_unsold(book)

    assert_equal "Your book was incorrectly marked sold at ube.ca", response.subject
    check_email_to_seller(response, book)
  end

protected

  def check_email_to_seller(response, book)
    assert_equal "dawson@ube.ca", response.from[0]
    assert_equal book.seller.email_address, response.to[0]

    assert_match /#{book.seller.name} -/, response.body
    assert_match /Title: #{book.barcode.title}/, response.body
    assert_match /Author: #{book.barcode.author}/, response.body
    assert_match /#{Exchange.current.address.address}/, response.body
    assert_match /#{Exchange.current.address.city}, #{Exchange.current.address.region}/, response.body
    assert_match %r{http://ube.ca/status\?email=jack%40example.com}, response.body
    assert_match %r{http://ube.ca/about/help}, response.body
    assert_match %r{http://ube.ca/}, response.body
  end
end
