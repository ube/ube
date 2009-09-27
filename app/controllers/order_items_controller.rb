class OrderItemsController < ApplicationController

  def destroy
    order = Order.find(params[:order_id])
    book = Book.find(params[:id])
    order.remove_book(book)
    book.stock!
    flash[:notice] = 'Book Removed.'
    redirect_to orders_path
  end

end
