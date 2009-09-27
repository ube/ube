class SellersController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    render exception.record.new_record? ? :new : :edit
  end

  def index
    return if params[:q].blank?
    sort 'name'
    @sellers = Seller.find_with_ferret queryize(params[:q]), { :sort => sort_by, :page => params[:page], :per_page => 20 }
    redirect_to seller_path(@sellers.first) if @sellers.total_entries == 1
  end

  def show
    @seller = Seller.find(params[:id])
    sort 'barcodes.title'
    @books = @seller.books.paginate :include => [ :barcode, :creator, :updater ], :order => order_by, :page => params[:page], :per_page => 50
  end

  def new
    edit
  end

  def create
    edit
  end

  def edit
    @seller = params[:id] ? Seller.find(params[:id]) : Seller.new

    session[:last_seller_search] = request.env['HTTP_REFERER'] if request.get?

    if request.post? or request.put?
      @seller.attributes = params[:seller]
      @seller.save!

      flash[:notice] = 'Seller Saved!'
      if params[:add_a_book] == 'yes'
        redirect_to new_seller_book_path(:seller_id => @seller)
      else
        redirect_to @seller.new_record? ? seller_path(@seller) : session[:last_seller_search] || seller_path(@seller)
      end
      return
    end

    render @seller.new_record? ? :new : :edit
  end

  def update
    edit
  end

  def contract
    @seller   = Seller.find(params[:id])
    @books    = @seller.books.unreclaimed.with(:barcode)
    @seller.print_contract!
    @seller.send_welcome_email!
    render :layout => false
  end

  def pay_service_fee
    @seller = Seller.find(params[:id])
    @seller.pay_service_fee!
    flash[:notice] = 'Paid service fee.'
    redirect_to seller_path(@seller)
  end

  def unpay_service_fee
    @seller = Seller.find(params[:id])
    @seller.unpay_service_fee!
    flash[:notice] = 'Unpaid service fee.'
    redirect_to seller_path(@seller)
  end

  def destroy
    seller = Seller.with(:books).find(params[:id])
    if seller.destroy
      flash[:notice] = 'Seller Deleted.'
    else
      flash[:error]  = 'This seller is still active. It cannot be deleted.'
    end
    redirect_to sellers_path
  end
end
