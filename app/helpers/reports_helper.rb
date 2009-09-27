module ReportsHelper
  def row(title, collection, options = {})
    content_tag('tr', 
      content_tag('td', title, :class => 'title') +
      collection.inject('') { |acc, val| acc + content_tag('td', "#{options[:before_text]}#{val}") } +
      content_tag('td', "#{options[:before_text]}#{collection.sum}"),
      :class => options[:class])
  end
end