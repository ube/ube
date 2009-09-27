class PeopleController < ApplicationController
  rescue_from ActiveRecord::RecordInvalid do |exception|
    render (exception.record.new_record? ? :new : :edit)
  end

  filter_parameter_logging :password, :password_confirmation
  skip_before_filter :login_required, :only => [ :forgot, :reset ]
  deny_unless_user_can 'edit_accounts', :except => [ :change_password, :forgot, :reset ]

  def index
    @people = Person.with(:roles).ordered('name')
  end

  def new
    edit
  end

  def create
    edit
  end

  def edit
    @person = params[:id] ? Person.with(:roles).find(params[:id], :readonly => false) : Person.new
    @roles = Person.current.available_roles

    if request.post? or request.put?
      @person.attributes = params[:person]
      @person.save!

      for role in @roles do
        if params[:"role_#{role.name}"]
          @person.can(role.name)
        else
          @person.cannot(role.name)
        end
      end

      flash[:notice] = 'Account Saved!'
      redirect_to people_path
      return
    end

    render (@person.new_record? ? :new : :edit)
  end

  def update
    edit
  end

  def change_password
    @person = Person.current
    if request.post?
      @person.attributes = params[:person].reject { |k,v| ![ 'password', 'password_confirmation' ].include?(k) }
      # require the person to set a new password
      @person.password_required = true
      if @person.save
        flash[:notice] = 'Password Saved!'
        redirect_to home_path
      end
    end
  end

  def destroy
    # hack to get around rails failing silently when a route doesn't fit its standards
    if params[:ids] or params[:id] != 'dummy'
      ([params[:ids] || params[:id]]).flatten.each do |id|
        # hack to get around rails destroying associations, even when it correctly avoids destroying the object
        u = Person.find(id)
        if u.destroyable?
          u.destroy
          flash[:notice] = 'People Deleted.'
        else
          flash[:error] = "You can't delete #{u.name}."
        end
      end
    else
      flash[:error] = 'You did not select any accounts to delete.'
    end
    redirect_to people_path
  end

  def forgot
    if request.post?
      # Remember the email address
      @email_address = params[:person][:email_address] if params[:person]

      # Empty field errors
      if params[:person][:email_address].blank?
        flash.now[:error] = 'Please enter an email address.' and return
      end

      Person.send_password_reset(params[:person][:email_address])
      render 'people/sent_password_reset'
    end
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = 'Oops, unknown email address. Did you spell it right?'
  end

  def reset
    @person = Person.receive_password_reset(params[:token])

    if request.post?
      @person.attributes = params[:person]
      # require the person to set a new password
      @person.password_required = true
      if @person.save
        # password tokens can be used only once
        @person.destroy_password_token!
        flash[:notice] = 'Password Saved!'
        handle_login(@person)
        redirect_to home_path
      end
    end
  rescue ActiveRecord::RecordNotFound
    render 'people/couldnt_process_request'
  end
end
