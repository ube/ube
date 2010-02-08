module ApplicationHelper
  include AccessibleForm
  
  def private?
    !%w(about public).include?(params[:controller]) && !%w(forgot reset).include?(params[:action]) || params[:action] == 'dashboard' || params[:controller] == 'exchanges'
  end

  def page_title
    suffix = ' (' + Exchange.current.name + ')'
    if @page_title
      @page_title + suffix
    elsif ['index', 'list'].include?(params[:action])
      params[:controller].humanize + suffix
    else
      params[:action].humanize + ' ' + params[:controller].humanize.downcase.singularize + suffix
    end
  end

  # If the current action matches an action in options[:actions], set the tab to active
  # If the current action matches an action in options[:if], add a link to the tab
  def tab(name, path, options)
    if (options[:controllers].blank? or options[:controllers].include?(params[:controller])) and 
       (options[:actions].blank? or options[:actions].include?(params[:action]) and
       not (options[:except]||[]).include?(params[:action]))
      if (options[:actions]||['index']).include?(params[:action])
        contents = content_tag('span', name)
      elsif path.include?('/') or path.is_a?(Hash)
        contents = link_to(name, path, options[:html])
      else
        contents = link_to_function(name, path, options[:html])
      end
      content_tag('li', contents, { :class => options[:class] ? "active #{options[:class]}" : "active" })
    elsif path.include?('/') or path.is_a?(Hash)
      content_tag('li', link_to(name, path, options[:html]), { :class => options[:class] })
    else
      content_tag('li', link_to_function(name, path, options[:html]), { :class => options[:class] })
    end
  end

  def pluralize(count, noun)
    case count
    when 0 then "no #{noun.pluralize}"
    when 1 then "one #{noun}"
    else        "#{count} #{noun.pluralize}"
    end
  end

  def distance_of_time_in_fewer_words(from_time, to_time = Time.current, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
      when 0..1
        return (distance_in_minutes == 0) ? '< 1 min' : '1 min' unless include_seconds
        case distance_in_seconds
          when 0..4   then '< 5 secs'
          when 5..9   then '< 10 secs'
          when 10..19 then '< 20 secs'
          when 20..39 then '~30 secs'
          when 40..59 then '< a min'
          else             '1 min'
        end

      when 2..44           then "#{distance_in_minutes} mins"
      when 45..89          then '~1 hour'
      when 90..1439        then "~#{(distance_in_minutes.to_f / 60.0).round} hours"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(distance_in_minutes / 1440).round} days"
      when 43200..86399    then '~1 month'
      when 86400..525959   then "#{(distance_in_minutes / 43200).round} months"
      when 525960..1051919 then '~1 year'
      else                      "over #{(distance_in_minutes / 525960).round} years"
    end
  end

  def button_tag(value = "Save changes", options = {})
    tag :input, { :type => 'button', :name => 'commit', :value => value }.merge(options.stringify_keys)
  end
end
