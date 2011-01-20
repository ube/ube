class BooksController < ApplicationController
  deny_unless_user_can 'discover_seller', :only => [ :all ]
  deny_unless_user_can 'undo', :only => [ :destroy ]

  def index
    return if params[:q].blank?
    sort 'price'
    @books = Book.find_with_ferret queryize(params[:q], conditions.merge(:state => 'instock')), { :sort => sort_by, :page => params[:page], :per_page => 20 }, { :include => :barcode }
  end

  def all
    return if params[:q].blank?
    sort 'label'
    @books = Book.find_with_ferret queryize(params[:q], conditions), { :sort => sort_by, :page => params[:page], :per_page => 20 }, { :include => [ :barcode, :seller ] }
  end

  def new
    edit
  end

  def create
    edit
  end

  def edit
    @seller  = Seller.find(params[:seller_id])
    @book    = params[:id] ? @seller.books.with([ :seller, :barcode ]).find(params[:id], :readonly => false) : Book.new
    @barcode = @book.barcode || Barcode.new

    if request.post? or request.put?
      # get the barcode if it already exists
      tag = params[:barcode][:tag].delete('^0-9')
      @barcode = Barcode.find_by_tag(tag) || Barcode.new

      @book.attributes    = params[:book]
      @barcode.attributes = params[:barcode] if @barcode.new_record?

      # use the sanitized barcode
      @barcode.tag = tag if @barcode.new_record?

      # link this object to its associated objects
      @book.seller = @seller if @book.new_record?

      if @barcode.save
        @book.barcode = @barcode
        if @book.save
          flash[:notice] = "Book ##{@book.label} Saved!"
          if params[:add_a_book] == 'yes'
            redirect_to new_seller_book_path(:seller_id => @seller)
          elsif params[:print_a_contract] == 'yes'
            redirect_to contract_seller_path(@seller)
          else
            redirect_to seller_path(@seller)
          end
          return
        end
      end
    end

    render @book.new_record? ? :new : :edit
  end

  def update
    edit
  end

  def destroy
    seller = Seller.find(params[:seller_id])
    book = seller.books.find(params[:id]).destroy
    flash[:notice] = "Book ##{book.label} Deleted."
    redirect_to seller_path(seller, :page => params[:page], :sort_key => params[:sort_key], :sort_order => params[:sort_order])
  end

protected

  def conditions
    [ :cdrom, :study_guide, :package, :access_code, :state ].inject({}) do |memo, param|
      memo[param] = params[param] unless params[param].blank?
      memo
    end
  end
end
