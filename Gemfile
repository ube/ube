source 'http://rubygems.org'
ruby '1.8.7'

gem 'rails', '2.3.18'
gem 'pg'

# Core
gem 'andand'
gem 'delayed_job', '~> 2.0.5'

# Models
gem 'ferret', '~> 0.11.8.4'
gem 'acts_as_ferret', '~> 0.4.8' # 0.5 requires rails >= 3.0 and 0.4 is incompatible with Ruby 1.9.2, see preinitializer.rb
gem 'aws-s3'
gem 'paperclip', '~> 2.3.16' # 2.4 aws-sdk
gem 'utility_scopes'
gem 'mime-types', '~> 1.25' # for aws-s3 and paperclip; 2.0 requires ruby >= 1.9.2

# Controllers
gem 'will_paginate', '~> 2.3.16' # 3.0 requires rails >= 3.0

# Views
gem 'jrails'
gem 'RedCloth'

gem 'json'

group :test do
  gem 'rr'
end

group :production do
  gem 'unicorn'
  gem 'newrelic_rpm'
end
