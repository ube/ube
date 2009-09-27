class PublicController < ApplicationController
  skip_before_filter :login_required

  def search
    return if params[:q].blank?
    sort 'price'
    @books = Book.find_with_ferret queryize(params[:q], :state => 'instock'), { :sort => sort_by, :page => params[:page], :per_page => 20 }, { :include => :barcode }
  end

  def status
    return if params[:email].blank?
    sort 'books.state, books.label'
    @email  = params[:email].strip
    @seller = Seller.find_by_email_address(@email) or return
    @books  = @seller.books.with(:barcode).ordered order_by
    @total  = @books.inject(0) { |memo, book| book.sold? ? memo + book.price : memo }
  end

  def contract
    return if params[:email].blank?
    @email  = params[:email].strip
    @seller = Seller.find_by_email_address(@email) or return
    @books  = @seller.books.unreclaimed.with :barcode
    render :file => 'sellers/contract', :use_full_path => true unless @books.blank?
  end
end
