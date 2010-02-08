class ExchangesController < ApplicationController
  deny_unless_user_can 'edit_exchange'
  deny_unless_user_can 'reset_exchange', :only => [ :soft_reset, :hard_reset ]

  def show
    @exchange = Exchange.with(:address).first
  end

  def edit
    @exchange = Exchange.with(:address).first
    @address = @exchange.address

    if request.put?
      @exchange.attributes = params[:exchange]
      @address.attributes = params[:address]

      if @exchange.save and @address.save
        Exchange.destroy_current
        flash[:notice] = 'Exchange Saved!'
        redirect_to exchange_path and return
      end
    end

    render :edit
  end

  def update
    edit
  end

  # TODO: test this method
  def soft_reset
    @seller = Seller.find_by_name 'Book Exchange'
    if request.delete?
      Order.delete_all
      if @seller
        Book.delete_all [ "state <> 'instock'" ]
        Book.update_all [ 'seller_id = ?', @seller.id ]
      else
        Book.delete_all
      end
      Seller.delete_all [ '(contract_printed_at IS NULL OR contract_printed_at < ?) AND (updated_at IS NULL OR updated_at < ?)', 1.year.ago, 1.year.ago ]
      Seller.update_all :welcome_email_sent_at => nil, :paid_service_fee_at => nil, :welcome_back_sent_on => nil, :reclaim_reminder_sent_on => nil
      Book.rebuild_index
      Seller.rebuild_index
      flash[:notice] = 'Exchange Soft Reset!'
      redirect_to home_path
    end
  end

  # TODO: test this method
  def hard_reset
    if request.delete?
      Order.delete_all
      Book.delete_all
      Seller.delete_all [ '(contract_printed_at IS NULL OR contract_printed_at < ?) AND (updated_at IS NULL OR updated_at < ?)', 1.year.ago, 1.year.ago ]
      Seller.update_all :welcome_email_sent_at => nil, :paid_service_fee_at => nil, :welcome_back_sent_on => nil, :reclaim_reminder_sent_on => nil
      Book.rebuild_index
      Seller.rebuild_index
      flash[:notice] = 'Exchange Hard Reset!'
      redirect_to home_path
    end
  end
end
