class SoldBooksController < ApplicationController
  deny_unless_user_can 'undo'

  def index
    return if params[:q].blank?
    sort 'price'
    @books = Book.find_with_ferret queryize(params[:q], :state => 'sold'), { :sort => sort_by, :page => params[:page], :per_page => 20 }, { :include => :barcode }
  end

  def destroy
    book = Book.find(params[:id])
    book.stock!
    render :update do |page|
      page.replace_html dom_id(book), 'Unsold'
      page.visual_effect :highlight, dom_id(book), :duration => 0.5
    end
  end
end
