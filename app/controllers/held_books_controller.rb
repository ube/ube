class HeldBooksController < ApplicationController
  def update
    book = Book.find(params[:id])
    book.hold!
    render :update do |page|
      page.replace_html dom_id(book), 'Held'
      page.visual_effect :highlight, dom_id(book), :duration => 0.5
    end
  end

  def destroy
    book = Book.find(params[:id])
    book.stock!
    render :update do |page|
      page.replace_html dom_id(book), 'In-stock'
      page.visual_effect :highlight, dom_id(book), :duration => 0.5
    end
  end
end
