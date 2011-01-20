module BooksHelper
  def status(book)
    if book.reclaimed?
      if book.sold_at
        status_html('reclaimed', 'Money claimed')
      else
        status_html('reclaimed', 'Book reclaimed')
      end
    elsif book.sold?
      status_html('sold')
    elsif book.held?
      status_html('instock', 'Held')
    elsif book.ordered? and logged_in?
      status_html('instock', 'Ordered')
    elsif book.lost? and logged_in?
      status_html('lost')
    else
      status_html('instock', 'In-stock')
    end
  end

  def action(book)
    alt = "#{action_caption(book)} by #{action_actor(book)} at #{action_time(book)}"
    image_tag 'clock.png', :size => '19x19', :alt => alt, :title => alt
  end

  def action_caption(book)
    if book.reclaimed?
      if book.sold_at
        'Money claimed'
      else
        'Book reclaimed'
      end
    elsif book.sold?
      'Sold'
    elsif book.lost?
      'Lost'
    else
      'Added'
    end
  end

  def action_actor(book)
    book.updater.nil? ? (book.creator.nil? ? 'unknown' : book.creator.name) : book.updater.name
  end

  def action_time(book)
    (book.reclaimed_at || book.lost_at || book.sold_at || book.created_at).strftime('%I:%M%p %a, %b %d').downcase.titleize
  end

  def number_to_price(price)
    number_to_currency(price, {:precision => 0, :separator => ''}) unless price.blank? or price.to_i.zero?
  end

  def extras(book)
    extras  = ''
    extras += image_tag('extras/cdrom.png', :size => '25x25', :alt => 'CD-ROM', :title => 'CD-ROM') if book.cdrom?
    extras += image_tag('extras/study_guide.png', :size => '26x25', :alt => 'Study guide', :title => 'Study guide') if book.study_guide?
    extras += image_tag('extras/package.png', :size => '25x25', :alt => 'Package', :title => 'Package') if book.package?
    extras += image_tag('extras/lock-icon.png', :size => '25x25', :alt => 'Access code', :title => 'Access code') if book.access_code?
    extras
  end

protected

  def status_html(status, caption = nil)
    content_tag('span', image_tag("statuses/#{status}.png", :size => '8x8', :alt => '') + " #{(caption||status).humanize}", :class => status)
  end
end
