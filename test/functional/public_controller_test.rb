require File.dirname(__FILE__) + '/../test_helper'

class PublicControllerTest < ActionController::TestCase
  fixtures :sellers, :books, :barcodes, :exchanges, :addresses

  def setup
    Book.rebuild_index
  end

  def test_search
    get :search
    assert_render 'public/search'
    assert_not_assigns :books
    assert_select 'h3.empty', false
    assert_select 'caption', false
  end

  def test_search_with_no_results
    get :search, :q => 'not_valid'
    assert_render 'public/search'
    assert_assigns :books
    assert_select 'h3.empty'
    assert_select 'caption', false
    assert_equal 0, assigns(:books).size
  end

  def test_search_with_some_results
    get :search, :q => 'Shakespeare'
    assert_render 'public/search'
    assert_assigns :books
    assert_select 'h3.empty', false
    assert_select 'caption'
    assert_equal_with_permutation [ books(:instock), books(:bob_instock) ], assigns(:books)
  end



  def test_status
    get :status
    assert_render 'public/status'
    assert_not_assigns :seller, :books, :total
    assert_no_tag :tag => 'h3', :attributes => { :class => 'empty' }
    assert_no_tag :tag => 'caption'
  end

  def test_status_with_no_results
    get :status, :email => 'not_valid'
    assert_render 'public/status'
    assert_assigns :email
    assert_not_assigns :seller, :books, :total
    assert_tag :tag => 'h3', :attributes => { :class => 'empty' }
    assert_no_tag :tag => 'caption'
    assert_equal 'not_valid', assigns(:email)
  end

  def test_status_with_some_results
    get :status, :email => 'jack@example.com'
    assert_render 'public/status'
    assert_assigns :email, :seller, :books, :total
    assert_no_tag :tag => 'h3', :attributes => { :class => 'empty' }
    assert_tag :tag => 'caption'
    assert_equal 'jack@example.com', assigns(:email)
    assert_equal sellers(:jack), assigns(:seller)
    assert_equal_with_permutation [ books(:instock), books(:lost), books(:held), books(:ordered), books(:book_reclaimed), books(:money_reclaimed), books(:held_reclaimed), books(:sold) ], assigns(:books)
    assert_equal 2, assigns(:total)
  end



  def test_contract
    get :contract
    assert_render 'public/contract'
    assert_not_assigns :seller, :books
    assert_no_tag :tag => 'h3', :attributes => { :class => 'empty' }
    assert_no_tag :tag => 'caption'
  end

  def test_contract_with_no_results
    get :contract, :email => 'not_valid'
    assert_render 'public/contract'
    assert_assigns :email
    assert_not_assigns :seller, :books
    assert_tag :tag => 'h3', :attributes => { :class => 'empty' }
    assert_no_tag :tag => 'caption'
    assert_equal 'not_valid', assigns(:email)
  end

  def test_contract_with_some_results
    get :contract, :email => 'jack@example.com'
    assert_render 'sellers/contract'
    assert_assigns :email, :seller, :books

    assert_equal 'jack@example.com', assigns(:email)
    assert_equal sellers(:jack), assigns(:seller)
    assert_equal_with_permutation [ books(:instock), books(:sold), books(:lost), books(:held), books(:ordered) ], assigns(:books)
  end

end
