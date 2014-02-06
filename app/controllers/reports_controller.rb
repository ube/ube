class ReportsController < ApplicationController
  deny_unless_user_can 'contact_seller', :only => [ :emails ]
  deny_unless_user_can 'edit_accounts', :only => [ :outstanding, :summary ]

  def emails
    @emails = Seller.all(:conditions => ["email_address != '' AND contract_printed_at > ?", 6.months.ago]).collect(&:email_address)
  end

  def outstanding
    @claims_count  = Book.first(:select => 'COUNT(DISTINCT seller_id) AS count_all', :conditions => 'reclaimed_at IS NULL AND sold_at IS NOT NULL')[:count_all].to_i
    @sellers_count = Book.first(:select => 'COUNT(DISTINCT seller_id) AS count_all')[:count_all].to_i
    @total_claims  = Book.sum :price, :conditions => 'sold_at IS NOT NULL AND reclaimed_at IS NULL'

    @claims = Seller.paginate(
      :select => 'sellers.id, name, telephone, email_address, SUM(price) AS claims, COUNT(sold_at) AS books',
      :conditions => 'reclaimed_at IS NULL AND sold_at IS NOT NULL',
      :joins => :books,
      :group => 'sellers.id, name, telephone, email_address',
      :order => 'claims DESC',
      :page => params[:page],
      :per_page => 20
    )
  end

  def summary
    @from_date = params[:from_date] ? Date.parse(params[:from_date]) : Date.current
    @to_date = params[:to_date] ? Date.parse(params[:to_date]).succ : Date.current.succ

    if @from_date > @to_date
      flash.now[:error] = "'From' date must be before 'to' date." and return
    end

    sales           = Book.all :group => 'date',   :order => 'date', :select => "SUBSTR(CAST(sold_at AS CHAR(10)), 0, 11)             AS date, COUNT(*) AS count, SUM(price) AS sales, SUM(sale_price) AS total_sales", :conditions => { :sold_at => @from_date..@to_date}
    books           = Book.all :group => 'date',   :order => 'date', :select => "SUBSTR(CAST(created_at AS CHAR(10)), 0, 11)          AS date, COUNT(*) AS count", :conditions => { :created_at => @from_date..@to_date }
    sales_reclaimed = Book.all :group => 'date',   :order => 'date', :select => "SUBSTR(CAST(reclaimed_at AS CHAR(10)), 0, 11)        AS date, COUNT(*) AS count, SUM(price) AS claims", :conditions => [ 'sold_at IS NOT NULL AND reclaimed_at BETWEEN ? AND ?', @from_date, @to_date ]
    books_reclaimed = Book.all :group => 'date',   :order => 'date', :select => "SUBSTR(CAST(reclaimed_at AS CHAR(10)), 0, 11)        AS date, COUNT(*) AS count", :conditions => { :sold_at => nil, :reclaimed_at => @from_date..@to_date }
    early_reclaims  = Book.all :group => 'date',   :order => 'date', :select => "SUBSTR(CAST(reclaimed_at AS CHAR(10)), 0, 11)        AS date, COUNT(*) AS count", :conditions => [ 'reclaimed_at BETWEEN ? AND ? AND reclaimed_at < ?', @from_date, @to_date, Exchange.current.reclaim_starts_on ]
    service_fees    = Seller.all :group => 'date', :order => 'date', :select => "SUBSTR(CAST(paid_service_fee_at AS CHAR(10)), 0, 11) AS date, COUNT(*) AS count", :conditions => { :paid_service_fee_at => @from_date..@to_date }

    current_year = current_month = nil

    @from_date.upto(@to_date) do |date|
      if [ books, sales, books_reclaimed, sales_reclaimed, early_reclaims, service_fees ].any? { |array| today?(array, date) }

        if date.year == current_year
          @years.last[:colspan] += 1
        else
          @years  = (@years||[]) << { :year => date.year, :colspan => 1 }
          current_year = date.year
        end

        if date.month == current_month
          @months.last[:colspan] += 1
        else
          @months = (@months||[]) << { :month => date.strftime('%b'), :colspan => 1 }
          current_month = date.month
        end

        @days = (@days||[]) << date.day

        book           = today?(books, date) ? books.shift : {}
        sale           = today?(sales, date) ? sales.shift : {}
        book_reclaimed = today?(books_reclaimed, date) ? books_reclaimed.shift : {}
        sale_reclaimed = today?(sales_reclaimed, date) ? sales_reclaimed.shift : {}
        early_reclaim  = today?(early_reclaims, date) ? early_reclaims.shift : {}
        service_fee    = today?(service_fees, date) ? service_fees.shift : {}

        early_reclaim[:total] = early_reclaim[:count].to_i * Exchange.current.early_reclaim_penalty
        service_fee[:total]   = service_fee[:count].to_i   * Exchange.current.service_fee

        @sales          = (@sales||[])          << sale[:sales].to_i
        @fees           = (@fees||[])           << sale[:total_sales].to_i - sale[:sales].to_i
        @total_sales    = (@total_sales||[])    << sale[:total_sales].to_i
        @claims         = (@claims||[])         << -sale_reclaimed[:claims].to_i
        @early_reclaims = (@early_reclaims||[]) << early_reclaim[:total].to_i
        @service_fees   = (@service_fees||[])   << service_fee[:total].to_i
        @deposits       = (@deposits||[])       << sale[:total_sales].to_i - sale_reclaimed[:claims].to_i + early_reclaim[:total].to_i + service_fee[:total].to_i

        @books_counts  = (@books_counts||[]) << book[:count].to_i
        @sales_counts  = (@sales_counts||[]) << sale[:count].to_i
        @books_reclaimed_counts = (@books_reclaimed_counts||[]) << book_reclaimed[:count].to_i
        @sales_reclaimed_counts = (@sales_reclaimed_counts||[]) << sale_reclaimed[:count].to_i
      end
    end

    @sellers_count = Book.first(:select => 'COUNT(DISTINCT seller_id) AS count_all')[:count_all].to_i
  rescue ArgumentError
    flash[:error] = 'The date is invalid.'
    redirect_to :back
  end

protected

  def today?(array, date)
    !array.empty? && array.first[:date] == date.to_s
  end
end
