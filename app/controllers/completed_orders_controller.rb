class CompletedOrdersController < ApplicationController

  def index
    @orders = Order.paginate :conditions => [ 'completed_at IS NOT NULL' ], :include => [ :updater, { :books => :barcode } ], :order => 'completed_at DESC', :page => params[:page], :per_page => 20
  end

  def update
    order = Order.find(params[:id])
    order.complete!
    if params[:print_receipt] == 'yes'
      redirect_to receipt_completed_order_path(params[:id]) and return
    end
    flash[:notice] = "Checkout Completed! <a href=\"#{receipt_completed_order_path(params[:id])}\">Print a Receipt</a>."
    redirect_to orders_path
  end

  def receipt
    @order    = Order.with({ :books => :barcode }).find(params[:id])
    render :layout => false
  end

end
