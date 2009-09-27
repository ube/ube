module SellersHelper
  def if_email_address_is_taken
    if @seller.errors.any? { |field, msg| field == 'email_address' && msg =~ /is taken/ }
      @existing = Seller.find_by_email_address(@seller.email_address)
      yield
    end
  end
end