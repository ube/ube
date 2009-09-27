class SessionsController < ApplicationController
  filter_parameter_logging :password
  skip_before_filter :login_required

  def new
    redirect_to home_path if logged_in?
  end

  def create
    redirect_to home_path and return if logged_in?

    # Remember the username
    @name = params[:person][:name] if params[:person]

    # Empty field errors
    if params[:person][:name].blank? or params[:person][:password].blank?
      fields = []
      fields << 'username' if params[:person][:name].blank?
      fields << 'password' if params[:person][:password].blank?
      flash.now[:error] = "Please enter a #{fields.to_sentence}."
      render :new and return
    end

    u = Person.authenticate(params[:person][:name], params[:person][:password])
    handle_login(u)
    redirect_back_or_default home_path
  rescue ActiveRecord::RecordNotFound
    flash.now[:error] = 'Oops, unknown username. Did you spell it right? Also, make sure <em>Caps Lock</em> is off.'
    render :new
  rescue Person::NotAuthenticated
    flash.now[:error] = "Oops, wrong password. Make sure <em>Caps Lock</em> is off and try again, or <a href=\"#{url_for(:controller => 'people', :action => 'forgot')}\">retrieve your password</a>."
    render :new
  end

  def destroy
    handle_logout if logged_in?
    flash[:notice] = 'You are signed out.'
    redirect_to new_session_path
  end
end
