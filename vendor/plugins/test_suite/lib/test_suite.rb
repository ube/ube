module TestSuite

  module BasicAssertions
    def assert_false(boolean)
      assert !boolean
    end
    
    def assert_equal_with_permutation(a, b)
      # A intersect B = A => A contained in B
      # B intersect A = B => B contained in A
      # Therefore, A = B
      assert (a & b == a) && (b & a == b)
    end
  end
  
  ### Controllers ###############################################################

  module ControllerAssertions
    def assert_render(template)
      assert_template template
      assert_response :success
    end

    def assert_assigns(*objects)
      objects.each do |object|
        assert_not_nil assigns(object.to_sym), "Assigns no @#{object}"
      end
    end

    def assert_not_assigns(*objects)
      objects.each do |object|
        assert_nil assigns(object.to_sym), "Assigns @#{object}"
      end
    end
  
    def assert_flash(key)
      assert_not_nil flash[key]
    end

    def assert_no_flash(key)
      assert_nil flash[key]
    end



    # Forms

    # Remember form values
    def assert_remember(action, template, attribs, object, *attributes)
      attributes.each do |attribute|
        post action, object.to_sym => { attribute.to_sym => '1' }.merge(attribs)
        assert_render template
        assert_assigns object, "#{object}"
      
        assert_equal '1', assigns(object).send(attribute).to_s, "#{object}.#{attribute}"
      end
    end

    # Report validation errors
    def assert_report(action, template, params, object, value, *attributes)
      attributes.each do |attribute|
        post action, { object.to_sym => { attribute.to_sym => value } }.merge(params)
        assert_render template
        assert_assigns object, "#{object}"
      
        assert_assigns_errors object, attribute
      end
    end



    # Controller errors - Agile Web Development with Rails page 166
  
    def assert_assigns_errors(object, attribute)
      assert_error_tag
      # just check that it assigns errors for now
      assert assigns(object.to_sym).errors.on(attribute.to_sym)
    end
  
    def assert_error_tag
      assert_tag error_message_field
    end

    def assert_no_error_tag
      assert_no_tag error_message_field
    end

    # Matches the output of ActionView::Base.field_error_proc
    def error_message_field
      { :tag => 'span', :attributes => { :class => 'fielderror' } }
    end
  end
  
  ### Models ####################################################################

  module ModelAssertions
    # Model errors - http://www.bigbold.com/snippets/posts/show/1796
  
    def assert_invalid(object)
      assert !object.valid?
    end

    # Test for a specific error
    def assert_error(object, attribute, message)
      assert_invalid object
      assert_errors_on object, attribute
      assert_errors_include object, attribute, message
    end
  
    def assert_errors_on(object, attribute)
      assert object.errors.on(attribute), "No validation error on #{attribute.to_s}"
    end
  
    def assert_no_errors_on(object, attribute)
      assert !object.errors.on(attribute), "Validation error on #{attribute.to_s}"
    end
  
    def assert_errors_include(object, attribute, message)
      assert object.errors.on(attribute).to_a.include?(message), "\"#{message}\" expected but was \"#{object.errors.on(attribute).to_s}\""
    end
  
  
  
    # Model- and instance-level assertions

    # http://rubyforge.org/snippet/detail.php?type=snippet&id=114
    # http://project.ioni.st/post/216
    #
    #  def test_new_publication
    #    assert_change Publication, :count do
    #      post :create, :publication => {...}
    #      # ...
    #    end
    #  end
    # 
    def assert_change(atom, *attributes)
      initial_values = {}
      attributes.each do |attribute|
        initial_values[attribute] = atom.send(attribute)
      end

      yield

      atom.reload if atom.respond_to?(:reload)
      attributes.each do |attribute|
        assert_not_equal initial_values[attribute], atom.send(attribute), "#{atom}##{attribute}"
      end
    end
  
    def assert_no_change(atom, *attributes)
      initial_values = {}
      attributes.each do |attribute|
        initial_values[attribute] = atom.send(attribute)
      end
    
      yield

      atom.reload if atom.respond_to?(:reload)
      attributes.each do |attribute|
        assert_equal initial_values[attribute], atom.send(attribute), "#{atom}##{attribute}"
      end
    end

    # Use this method to test callbacks
    # This test requires a <tt>create_record</tt> method
    def assert_filter(attribute, initial_value, final_value)
      object = create_record(attribute.to_sym => initial_value)
      object.reload
      assert_equal final_value, object.send(attribute), "#{object}##{attribute}"
      object.destroy
    end
  
  
  
    # CRUD actions - http://www.bigbold.com/snippets/posts/show/1665
  
    def assert_create(model, options)
      assert_difference model, :count do
        object = model.new(options)
        assert object.save, "#{object.errors.full_messages.collect.to_s}"
        # I should test to see if the passed values are equal to the saved values here,
        # but I can't be sure they're equal due to before filters
        assert_kind_of model, object
      end
    end
  
    def assert_update(model, id, options)
      assert_no_change model, :count do
        assert object = model.find(id)
        assert object.update_attributes(options), "#{object.errors.full_messages.collect.to_s}"
        # I should test to see if the passed values are equal to the saved values here,
        # but I can't be sure they're equal due to before filters
        assert_kind_of model, object
      end
    end
  
    def assert_destroy(model, id)
      assert_difference model, :count, -1 do
        assert object = model.find(id)
        assert object.destroy
        assert_raise(ActiveRecord::RecordNotFound) { model.find(id) }
      end
    end
  
  
  
    # Validations
  
    # refactoring of http://johnwilger.com/articles/2005/12/07/a-bit-of-dryness-for-unit-tests-in-rails
    # For all of these assertions, you can set a custom error message using options[:message]
    # All these assertions can take as many attributes as you like
    def assert_presence_of_attributes(model, options = {}, *attributes)
      message = options[:message] || I18n.translate('activerecord.errors.messages.blank')

      attributes.each do |attribute|
        object = model.new
        assert_error object, attribute, message
      end
    end

    # This assertion needs a fixture in order to call model.first
    # Set options[:case_insensitive] to true if your validation is case-insensitive
    def assert_uniqueness_of_attributes(model, options = {}, *attributes)
      message = options[:message] || I18n.translate('activerecord.errors.messages.taken')

      # here's where we need the fixture
      existing = model.first

      attributes.each do |attribute|
        if options[:case_insensitive]
          # try uppercase
          object = model.new(attribute.to_sym => existing.send(attribute) && existing.send(attribute).upcase)
          assert_error object, attribute, message
        
          # try lowercase
          object = model.new(attribute.to_sym => existing.send(attribute) && existing.send(attribute).downcase)
          assert_error object, attribute, message
        else
          # try the same case
          object = model.new(attribute.to_sym => existing.send(attribute))
          assert_error object, attribute, message
        end
      end
    end

    # This assertions requires you to set the minimum length using options[:min]
    def assert_minimum_length_of_attributes(model, options = {}, *attributes)
      message = options[:message] || I18n.translate('activerecord.errors.messages.too_short', :count => options[:min])

      attributes.each do |attribute|
        object = model.new(attribute.to_sym => 'x' * (options[:min] - 1))
        assert_error object, attribute, message
      end
    end

    # This assertions requires you to set the maximum length using options[:max]
    def assert_maximum_length_of_attributes(model, options = {}, *attributes)
      message = options[:message] || I18n.translate('activerecord.errors.messages.too_long', :count => options[:max])

      attributes.each do |attribute|
        object = model.new(attribute.to_sym => 'x' * (options[:max] + 1))
        assert_error object, attribute, message
      end
    end
  
    # This assertions requires you to set the minimum and maximum lengths using options[:range]
    def assert_length_of_attributes(model, options = {}, *attributes)
      # use the default error messages
      assert_minimum_length_of_attributes(model, options.merge(:min => options[:range].begin, :message => nil), *attributes)
      assert_maximum_length_of_attributes(model, options.merge(:max => options[:range].end, :message => nil), *attributes)
    end
  
    def assert_confirmation_of_attributes(model, options = {}, *attributes)
      message = options[:message] || I18n.translate('activerecord.errors.messages.confirmations')

      attributes.each do |attribute|
        object = model.new(attribute.to_sym => 'yes', "#{attribute.to_s}_confirmation".to_sym => 'no')
        assert_error object, attribute, message
      end
    end

    # Test values - http://habtm.com/articles/2006/06/24/easier-model-validation-through-better-helper-methods
    # This is useful for testing validates_format_of and validates_numericality_of validations
    def assert_valid_values(object, attribute, *values)
      values.flatten.each do |value|
        o = object.dup
        o.send("#{attribute}=", value)
        assert o.valid?
        assert_no_errors_on o, attribute
      end
    end

    def assert_invalid_values(object, attribute, *values)
      values.flatten.each do |value|
        o = object.dup
        o.send("#{attribute}=", value)
        assert_invalid o
        assert_errors_on o, attribute
      end
    end

    def assert_invalid_values_on_create(attribute, options, *values)
      values.flatten.each do |value|
        o = create_record(options.merge({ attribute => value }))
        assert_invalid o
        assert_errors_on o, attribute
      end
    end
  end
  
  ### Integration ###############################################################

  module IntegrationDSL
    def goes_to(url, template)
      get url
      assert_render template
    end
    
    def is_redirected_to(template)
      assert_response :redirect
      follow_redirect!
      assert_render template
    end
    
    include BasicAssertions
    include ControllerAssertions
    include ModelAssertions
  end  
  
end
