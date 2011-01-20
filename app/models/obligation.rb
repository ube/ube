class Obligation < ActiveRecord::Base
  require 'utility_scopes'
  belongs_to :role
  belongs_to :person
end
