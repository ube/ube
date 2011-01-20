class CartItemsController < ApplicationController

  def index
    # @cart.books is an array of book IDs
    @books = Book.find(@cart.books,:include=>:barcode)
  end

  def update
    book = Book.find(params[:id])

    render :update do |page|
      begin
        @cart.add_book(book)
        page.replace_html 'cart_header', :partial => 'carts/header'
        page.replace_html dom_id(book), :partial => 'carts/go_to_cart'
      rescue Cart::AlreadyInCart
        page.replace_html dom_id(book), 'Already in cart'
      rescue Book::NotInStock
        page.replace_html dom_id(book), 'No longer in-stock'
      rescue Book::InOrder
        page.replace_html dom_id(book), 'In another cart'
      end
      page.visual_effect :highlight, dom_id(book)
    end
  end

  def destroy
    book = Book.find(params[:id])

    render :update do |page|
      begin
        @cart.remove_book(book)
        page.replace_html 'cart_header', :partial => 'carts/header'
        if @cart.books.empty?
          page.remove 'cart_items'
          page.show 'cart_empty'
          page.visual_effect :highlight, 'cart_empty'
        else
          page.remove dom_id(book)
          page.replace_html 'cart_total', :partial => 'carts/total'
          page.visual_effect :highlight, 'cart_total'
        end
      rescue Cart::NotInCart # Only occurs on double-clicks, so ignore it
      end
    end
  end
end
