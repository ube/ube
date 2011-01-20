class Role < ActiveRecord::Base
  require 'utility_scopes'
  has_many :obligations, :dependent => :destroy
  has_many :people, :through => :obligations
end
