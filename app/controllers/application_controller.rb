require_dependency 'cart'

class ApplicationController < ActionController::Base
  QUERY_SUBST = {
    /\b(?:the|of|and|a|to|in|for|&|an|with|la|le|les|de|du|et|on|al|by|only)\b/i => '',
    /\bvolume\b/i => 'vol',
    /\"/ => '',
    /^(?:\*| )+/ => '',
    /(?:\*| )+$/ => '',
  }.freeze

  include Authentication

  before_filter :login_required
  before_filter :find_cart

  helper :sort, :books

  protected

  def find_cart
    @cart = (session[:cart] ||= Cart.new)
  end

  def sort(default_key, default_order = 'asc')
    @sort_name = params[:controller] + params[:action] + '_sort'

    if params[:sort_key]
      session[@sort_name] = { :key => params[:sort_key], :order => params[:sort_order] }
    elsif session[@sort_name].nil?
      session[@sort_name] = { :key => default_key, :order => default_order }
    end
  end

  def order_by
    "#{session[@sort_name][:key]} #{session[@sort_name][:order]}"
  end

  def sort_by
    return Ferret::Search::SortField.new("sort_#{session[@sort_name][:key].gsub(/.+\./, '')}", :reverse => session[@sort_name][:order] == 'desc')
  end

  def queryize(query, conditions = {})
    QUERY_SUBST.each { |k,v| query.gsub!(k, v) }
    "*#{query.squeeze(' ')}*" + conditions.inject('') { |memo,condition| memo + " #{condition[0]}:#{condition[1]}" }
  end
end
