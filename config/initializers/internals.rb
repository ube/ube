# show SQL in script/console
ActiveRecord::Base.logger = Logger.new(STDOUT) if 'irb' == $0

# error field appearance
ActionView::Base.field_error_proc = Proc.new do |html_tag, instance| 
  "<span class=\"fielderror\">#{html_tag}<strong>#{instance.error_message.is_a?(Array) ? instance.error_message.to_sentence : instance.error_message}.</strong></span>"
end
