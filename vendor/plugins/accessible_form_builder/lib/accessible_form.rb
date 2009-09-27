module AccessibleForm
  @@required_field = nil
  
  # Cache this tag
  def required_field
    @@required_field ||= content_tag('abbr', '*', :title => '(required)')
  end

  def my_form_for(name, object = nil, options = nil, &proc)
    # set the form's class
    options[:html] ||= {}
    options[:html][:class] = 'base ' + options[:html][:class]

    raise ArgumentError, "Missing block" unless block_given?
    form_for(name, object, (options||{}).merge(:builder => AccessibleFormBuilder), &proc)
  end
  
  def my_fields_for(name, object = nil, options = nil, &proc)
    raise ArgumentError, "Missing block" unless block_given?
    fields_for(name, object, (options||{}).merge(:builder => AccessibleFormBuilder), &proc)
  end
  
  def fieldset(legend = nil, &block)
    concat '<fieldset>'
    concat(content_tag('legend', legend)) if legend
    concat '<ol>'
    yield
    concat '</ol>'
    concat '</fieldset>'
  end
  
  def inline_fieldset(&block)
    concat '<li>'
    concat '<fieldset class="inline">'
    concat '<ol>'
    yield
    concat '</ol>'
    concat '</fieldset>'
    concat '</li>'
  end

  %w(radio_buttons check_boxes).each do |selector|
    class_eval %Q{
      def #{selector}(legend = nil, required = false, &block)
        concat '<li>'
        concat '<fieldset class="options">'
        if legend
          legend = content_tag('strong', legend + required_field) if required
          concat content_tag('legend', legend)
        end
        yield
        concat '</fieldset>'
        concat '</li>'
      end
    }
  end

  # based on error_messages_for in ActionView::Helpers::ActiveRecordHelper
  # setting :full_messages to true displays the individual error messages in the error summary
  def error_messages_on(*objects)
    errors = []
        
    objects.each do |object|
      object = instance_variable_get("@#{object}") if object.kind_of?(String)
      next unless object and not object.errors.empty?
      errors << object.errors.collect { |field, msg| msg[/^[a-z]/] ? content_tag('li', field.humanize + ' ' + msg) : content_tag('li', msg) }
    end
    
    return if errors.blank?
    
    content_tag('div',
      content_tag('h2', "Please check the following:") + 
      content_tag('ul', errors),
      'id' => 'errors', 'class' => 'errors')
  end

  class AccessibleFormBuilder < ActionView::Helpers::FormBuilder
    @@required_field = nil
    
    @@prepare_field = %Q{
      return super if options[:super]
      label = options.delete(:label) || method.to_s.humanize
      label = @template.content_tag('strong', label + required_field) if options.delete(:required)
      before_text = options[:before_text] ? @template.content_tag('span', options.delete(:before_text)) : ''
      after_text  = options[:after_text]  ? @template.content_tag('em', options.delete(:after_text))    : ''
    }
    
    @@render_field = %Q{
      @template.content_tag('li',
        @template.content_tag('label', label, :for => object_name.to_s + '_' + method.to_s) +
        ' ' + before_text + super + after_text, :class => options.delete(:class))
    }

    cattr_accessor :required_field, :prepare_field, :render_field
    
    def required_field
      @@required_field ||= @template.content_tag('abbr', '*', :title => '(required)')
    end

    # You can set :required to style the field as a required field
    #             :label to set a custom label
    #             :class to give the li and the field a class
    #             :before_text to before_text anything to the input field
    %w(file_field password_field text_field text_area).each do |selector|
      class_eval %Q{
        def #{selector}(method, options = {})
          #{prepare_field}

          # select the field's contents on focus
          options[:onfocus] = 'this.select()'

          #{render_field}
        end
      }
    end
    %w(date_select datetime_select).each do |selector|
      class_eval %Q{
        def #{selector}(method, options = {})
          #{prepare_field}
          #{render_field}
        end
      }
    end
    %w(collection_select).each do |selector|
      class_eval %Q{
        def #{selector}(method, collection, value_method, text_method, options = {}, html_options = {})
          #{prepare_field}
          #{render_field}
        end
      }
    end
    %w(select).each do |selector|
      class_eval %Q{
        def #{selector}(method, choices, options = {}, html_options = {})
          #{prepare_field}
          #{render_field}
        end
      }
    end

    def radio_button(method, tag_value, options = {})
      label = options[:label] ? options.delete(:label) : tag_value
      @template.content_tag('label', super + ' ' + label)
    end
    
    def check_box(method, options = {}, checked_value = '1', unchecked_value = '0')
      label = options[:label] ? options.delete(:label) : checked_value
      @template.content_tag('label', super + ' ' + label)
    end
  end
  
end