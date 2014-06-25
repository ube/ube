# This file is used by Rack-based servers to start the application.

# @see http://guides.rubyonrails.org/v2.3.11/rails_on_rack.html#rackup
require ::File.expand_path('../config/environment',  __FILE__)
use Rails::Rack::LogTailer
use Rails::Rack::Static
run ActionController::Dispatcher.new
