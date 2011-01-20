# All session and cookie stuff should go on in this module
# This module also tends Person.current
module Authentication
  def self.included(controller)
    controller.send(:helper_method, :logged_in?)
    controller.before_filter(:create_current_person)
    controller.extend(ControllerClassMethods)
    controller.class_eval { include ControllerInstanceMethods}
  end

  module ControllerClassMethods
    def deny_unless_user_can(role, *args)
      append_before_filter(*args) { |controller| controller.authorize(role) }
    end
  end

  module ControllerInstanceMethods

    # Authorization

    def authorize(role)
      unless Person.current.can? role
        unless logged_in?
          store_location
          not_authenticated
        else
          not_authorized
        end
        return false
      end
      true
    end

  protected

    # Authentication

    def logged_in?
      not session[:person].nil?
    end

    # use as a before_filter
    def login_required
      unless logged_in?
        store_location
        not_authenticated
        return false
      end
      true
    end

    # stores the URI of the current request in the session
    def store_location
      session[:return_to] = request.request_uri
    end

    # redirects user to home page
    def not_authorized
      redirect_to home_path
      flash[:error] = "You are not authorized to do that."
    end

    # redirects user to login screen
    def not_authenticated
      redirect_to new_session_path
      flash[:error] = "Please login to continue."
    end

    # redirect to the URI stored by the most recent <tt>store_location</tt> or to the passed default
    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end

    # takes a person's ID and logs her in
    def handle_login(u)
      session[:person] = u.id
    end

    # do things in reverse order of login
    def handle_logout
      reset_session
    end



    # gets the current person on each request so that the session never goes stale
    def create_current_person
      if logged_in?
        Person.current = Person.with(:roles).find(session[:person])
      else
        Person.current = nil
      end
    end
  end
end
