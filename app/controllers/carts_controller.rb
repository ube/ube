class CartsController < ApplicationController

  def destroy
    @cart.empty!

    render :update do |page|
      page.replace_html 'cart_header', :partial => 'carts/header'
      page.remove 'cart_items'
      page.show 'cart_empty'
      page.visual_effect :highlight, 'cart_empty'
    end
  end
end
