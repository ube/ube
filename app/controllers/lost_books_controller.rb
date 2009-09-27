class LostBooksController < ApplicationController
  def index
    sort 'label'
    options = { :page => params[:page], :per_page => 20 }
    find_options = { :include => :barcode }
    conditions = { :state => 'lost' }
    if params[:q].blank?
      @books = Book.paginate options.merge(find_options).merge(:conditions => conditions, :order => order_by)
    else
      @books = Book.find_with_ferret queryize(params[:q], conditions), options.merge(:sort => sort_by), find_options
    end
  end

  def update
    book = Book.find(params[:id])
    book.lose!
    render :update do |page|
      page.replace_html dom_id(book), 'Lost'
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
