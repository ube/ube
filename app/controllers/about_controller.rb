class AboutController < ApplicationController
  skip_before_filter :login_required, :except => :dashboard
end
