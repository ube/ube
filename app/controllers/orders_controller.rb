class OrdersController < ApplicationController
  deny_unless_user_can 'checkout', :except => [ :create ]

  def index
    @orders = Order.all :conditions => { :completed_at => nil }, :include => [ :creator, { :books => :barcode } ], :order => 'orders.created_at ASC'
  end

  def create
    order = Order.create
    books = Book.find(@cart.books)
    order.fill!(books)
    @cart.empty!
    flash[:notice] = "Cart Sent to Checkout! <a href=\"#{orders_path}\">Go to Checkout</a>."
    redirect_to home_path
  end

  def destroy
    Order.find(params[:id]).destroy
    flash[:notice] = 'Cart Deleted.'
    redirect_to orders_path
  end
end
