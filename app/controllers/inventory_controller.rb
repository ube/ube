class InventoryController < ApplicationController

  def index
  end

  def all
    @books = Book.instock.with(:barcode).ordered('label')
    @page_title = 'Inventory'
    render :layout => false
  end

  def sold_on
    date = params[:sold_on] ? Date.parse(params[:sold_on]) : Date.current
    @page_title = "Sold on #{date}"
    @books = Book.sold_on(date)
    render :layout => false, :action => :all
  rescue ArgumentError
    flash[:error] = "The 'Sold on' date is invalid."
    redirect_to :back
  end

  def lost_on
    date = params[:lost_on] ? Date.parse(params[:lost_on]) : Date.current
    @page_title = "Lost on #{date}"
    @books = Book.lost_on(date)
    render :layout => false, :action => :all
  rescue ArgumentError
    flash[:error] = "The 'Lost on' date is invalid."
    redirect_to :back
  end
end
