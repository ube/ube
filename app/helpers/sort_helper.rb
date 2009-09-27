# http://dev.collaboa.org/repository/file/trunk/app/helpers/sort_helper.rb
# http://www.methods.co.nz/misc/sort_helper.rb
module SortHelper
  # Returns a table header <th> tag with a sort link for the named column attribute.
  #
  #   column       The name of the column
  #   :caption     The link text (defaults to titleized column name)
  #   :title       The th's title attribute (defaults to 'Sort by :caption')
  def sort_header_tag(column, options = {})
    key, order = session[@sort_name][:key], session[@sort_name][:order]
    if key == column
      if order.downcase == 'asc'
        klass, order = 'asc', 'desc'
      else
        klass, order = 'desc', 'asc'
      end
    else
      klass, order = nil, 'asc'
    end

    caption     = options.delete(:caption) || column.humanize.titleize
    sort_params = (params||{}).merge :sort_key => column, :sort_order => order
    options[:title] = "Sort by #{caption}" unless options[:title]
    options[:class] = "#{options[:class]} #{klass}" if klass

    content_tag 'th', link_to(caption, sort_params), options
  end
end
