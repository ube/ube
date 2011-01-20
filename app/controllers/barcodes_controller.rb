class BarcodesController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    render :edit
  end

  def index
    sort 'tag'
    options = { :page => params[:page], :per_page => 20 }
    if params[:q].blank?
      @barcodes = Barcode.paginate options.merge(:order => order_by)
    else
      @barcodes = Barcode.find_with_ferret queryize(params[:q]), options.merge(:sort => sort_by)
    end
    redirect_to edit_barcode_path(@barcodes.first) if @barcodes.total_entries == 1
  end

  def show
    render :update do |page|
      # get rid of noise
      tag = params[:value].delete('^0-9')
      # get rid of trailing 9's
      tag = tag[0..12] if tag[0..2] == '978' && tag[13] == 57
      barcode = Barcode.find_by_tag(tag)
      if barcode
        page << "$('#barcode_tag').attr('value', '#{barcode.tag}')"
        page << "$('#barcode_title').attr('value', '#{barcode.title}')"
        page << "$('#barcode_author').attr('value', '#{barcode.author}')"
        page << "$('#barcode_edition').attr('value', '#{barcode.edition}')"
        page << "$('#barcode_retail_price').attr('value', '#{barcode.retail_price}')"
        page << "$('#book_price').focus()"
        page.replace_html 'status', :partial => 'complete', :locals => { :barcode => barcode }
      else
        page.replace_html 'status', :partial => 'failure', :locals => { :tag => tag }
      end
      page.visual_effect :highlight, 'status'
    end
  end

  def edit
    @barcode = Barcode.find(params[:id])

    session[:last_barcode_search] = request.env['HTTP_REFERER'] if request.get?

    if request.put?
      @barcode.attributes = params[:barcode]
      @barcode.save!

      flash[:notice] = 'Barcode Saved!'
      redirect_to session[:last_barcode_search] || barcodes_path
      return
    end

    render :edit
  end

  def update
    edit
  end

  def destroy
    barcode = Barcode.find(params[:id],:include=>:books)
    if barcode.books.empty?
      barcode.destroy
      flash[:notice] = 'Barcode Deleted.'
    else
      flash[:error]  = 'This barcode is still in use. It cannot be deleted.'
    end
    redirect_to barcodes_path
  end
end
