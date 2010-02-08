class ReclamationsController < ApplicationController
  deny_unless_user_can 'undo', :only => [ :destroy ]

  def update
    seller = Seller.find(params[:seller_id])
    if params[:all]
      books = seller.books.reclaimable
    else
      books = seller.books.reclaimable.all :conditions => { :id => [params[:id]].flatten }
    end

    unless books.empty?
      flash[:notice] = ''
      flash[:alert] = ''
      if Date.current < Exchange.current.reclaim_starts_on
        flash[:alert] = "Charged early reclaim penalty.\n"
      elsif Date.current > Exchange.current.reclaim_ends_on
        flash[:alert] = "Marked as late reclaimer.\n"
      end

      unless seller.paid_service_fee_at?
        flash[:alert] += "Charged service fee.\n"
      end

      labels = books.inject([]) { |memo, book| book.instock? || book.held? ? memo << "<span>##{book.label}</span>" : memo }
      flash[:notice] += "Find #{labels.to_sentence}.\n" unless labels.empty?

      total = seller.reclaim!(books)

      if total > 0
        flash[:notice] += "Pay out $#{total}.\n"
      elsif total < 0
        flash[:notice] += "Collect $#{-total} from #{seller.name}.\n"
      end
    else
      flash[:error] = 'You did not select any unreclaimed books to reclaim.'
    end

    redirect_to seller_path(seller)
  end

  def destroy
    seller = Seller.find(params[:seller_id])
    if params[:all]
      books = seller.books.reclaimed
    else
      books = seller.books.reclaimed.all :conditions => { :id => [params[:id]].flatten }
    end

    unless books.empty?
      books.each { |book| book.unreclaim! }

      labels = books.inject([]) { |memo, book| memo << "##{book.label}" }
      flash[:notice] = "Unreclaimed #{labels.to_sentence}."
    else
      flash[:error] = 'You did not select any reclaimed books to unreclaim.'
    end

    redirect_to seller_path(seller)
  end
end
